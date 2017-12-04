require "active_switch/version"
require "active_switch/status"

module ActiveSwitch
  extend self

  NoRedisClient     = Class.new(StandardError)
  AlreadyRegistered = Class.new(ArgumentError)
  UnknownName       = Class.new(ArgumentError)

  STORAGE_KEY   = "active_switch_last_reported_ats".freeze
  REGISTRATIONS = {}

  class << self
    attr_writer :redis

    def redis
      @redis or raise NoRedisClient, "No redis client configured"
    end
  end

  def register(*args)
    if args[0].is_a?(Hash)
      args[0].each { |name, threshold_seconds| register(name, threshold_seconds) }
    else
      name, threshold_seconds = args[0].to_s, args[1]

      if REGISTRATIONS[name]
        raise AlreadyRegistered, "#{name} already registered"
      else
        REGISTRATIONS[name] = threshold_seconds
      end
    end
  end

  def report(name)
    name = cast_name(name)

    if block_given?
      yield.tap { mark_reported(name) }
    else
      mark_reported(name)
      true
    end
  end

  def status(name)
    name = cast_name(name)
    ts   = redis.hget(STORAGE_KEY, name)

    Status.new(name: name, last_reported_at: ts, threshold_seconds: REGISTRATIONS[name])
  end

  def all
    data = redis.hgetall(STORAGE_KEY)

    REGISTRATIONS.each_with_object({}) do |(name, threshold_seconds), obj|
      obj[name] = Status.new(name: name, last_reported_at: data[name],
                             threshold_seconds: threshold_seconds)
    end
  end

  def active
    all.select { |_, s| s.active? }
  end

  def inactive
    all.select { |_, s| s.inactive? }
  end

  # Considered private API

  def mark_reported(name)
    redis.hset(STORAGE_KEY, name, Time.now.to_i)
  end

  def cast_name(name)
    name.to_s.tap do |name|
      raise UnknownName, "#{name} not found" unless REGISTRATIONS[name]
    end
  end
end
