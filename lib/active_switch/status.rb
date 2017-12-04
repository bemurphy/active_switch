module ActiveSwitch
  class Status
    ACTIVE   = "ACTIVE".freeze
    INACTIVE = "INACTIVE".freeze

    attr_reader :name, :last_reported_at, :threshold_seconds

    def initialize(name:, last_reported_at:, threshold_seconds:)
      @name              = name.to_s
      @last_reported_at  = cast_timestamp(last_reported_at, cast_null: false)
      @threshold_seconds = threshold_seconds.to_i
    end

    def active?
      (cast_timestamp(last_reported_at) + threshold_seconds) > cast_timestamp(now)
    end

    def inactive?
      !active?
    end

    def state
      active? ? ACTIVE : INACTIVE
    end
    alias_method :to_s, :state

    private

    def now
      Time.now
    end

    def cast_timestamp(ts, cast_null: true)
      if cast_null
        Time.at((ts || 0).to_i)
      else
        ts ? Time.at(ts.to_i) : nil
      end
    end
  end
end
