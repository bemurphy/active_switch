require "active_switch/version"

module ActiveSwitch
  extend self

  NoRedisClient     = Class.new(StandardError)
  AlreadyRegistered = Class.new(ArgumentError)
  UnknownName       = Class.new(ArgumentError)

  STORAGE_KEY   = "active_switch_last_seen_ats".freeze
  REGISTRATIONS = {}

  class << self
    attr_writer :redis

    def redis
      @redis or raise NoRedisClient, "No redis client configured"
    end
  end

  def register(name, threshold_seconds)
    name = name.to_s

    if REGISTRATIONS[name]
      raise AlreadyRegistered, "#{name} already registered"
    else
      REGISTRATIONS[name] = threshold_seconds
    end
  end

  def report(name)
    name = cast_name(name)
    redis.hset(STORAGE_KEY, name, Time.now.to_i)
    true
  end

  def status(name)
    name = cast_name(name)
    ts   = redis.hget(STORAGE_KEY, name)

    Status.new(name: name, last_seen_at: ts, threshold_seconds: REGISTRATIONS[name])
  end

  def all
    data = redis.hgetall(STORAGE_KEY)

    REGISTRATIONS.each_with_object({}) do |(name, threshold_seconds), obj|
      obj[name] = Status.new(name: name, last_seen_at: data[name],
                             threshold_seconds: threshold_seconds)
    end
  end

  def active
    all.select { |_, s| s.active? }
  end

  def inactive
    all.select { |_, s| s.inactive? }
  end

  def cast_name(name)
    name.to_s.tap do |name|
      raise UnknownName, "#{name} not found" unless REGISTRATIONS[name]
    end
  end
end
