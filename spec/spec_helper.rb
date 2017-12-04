$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "active_switch"
require "mock_redis"

module ActiveSwitch
  def self.test_reset
    ActiveSwitch.redis = MockRedis.new
    ActiveSwitch::REGISTRATIONS.clear
  end
end

RSpec.configure do |config|
  config.before(:each) do
    ActiveSwitch.test_reset
  end
end
