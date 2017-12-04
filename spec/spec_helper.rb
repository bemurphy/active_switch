$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "active_switch"
require "mock_redis"

RSpec.configure do |config|
  config.before(:each) do
    ActiveSwitch.redis = MockRedis.new
    ActiveSwitch::REGISTRATIONS.clear
  end
end
