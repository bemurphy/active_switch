require "spec_helper"

RSpec.describe ActiveSwitch do
  let(:redis) { ActiveSwitch.redis }
  let(:storage_key) { ActiveSwitch::STORAGE_KEY }

  before do
    # Intentionally register with body strings and symbols
    ActiveSwitch.register("foo", 10)
    ActiveSwitch.register(:bar, 20)
  end

  it "has a version number" do
    expect(ActiveSwitch::VERSION).not_to be nil
  end

  describe ".register" do
    it "adds the name and threshold seconds to REGISTRATIONS" do
      expect(ActiveSwitch::REGISTRATIONS).to eq("foo" => 10, "bar" => 20)
    end

    it "raises AlreadyRegistered if a duplicate name is registered" do
      expect {
        ActiveSwitch.register(:foo, 10)
      }.to raise_error(ActiveSwitch::AlreadyRegistered)
    end

    it "can receive a hash of names and thresholds" do
      ActiveSwitch.test_reset

      ActiveSwitch.register({
        fizz: 11,
        "buzz" => 22,
      })

      expect(ActiveSwitch::REGISTRATIONS).to eq("fizz" => 11, "buzz" => 22)
    end
  end

  describe ".report" do
    it "stores an epoch seconds timestamp in redis when reporting" do
      ActiveSwitch.report(:foo)
      expect(redis.hget(storage_key, :foo).to_i).to be_within(1).of(Time.now.to_i)
    end

    it "can execute a block when given" do
      rtn = ActiveSwitch.report(:foo) { 2 + 2 }
      expect(rtn).to eq(4)
      expect(redis.hget(storage_key, :foo).to_i).to be_within(1).of(Time.now.to_i)
    end
  end

  describe ".status" do
    it "retrives a status instance for the name" do
      redis.hset(storage_key, :foo, 42)
      status = ActiveSwitch.status(:foo)

      expect(status).to be_a(ActiveSwitch::Status)
      expect(status.name).to eq("foo")
      expect(status.threshold_seconds).to eq(10)
      expect(status.last_reported_at).to eq(Time.at(42))
    end

    it "can return a status when no last reported at is set" do
      status = ActiveSwitch.status(:foo)
      expect(status).to be_a(ActiveSwitch::Status)
    end
  end

  describe ".all" do
    it "returns a hash of status of all registered names" do
      expect(ActiveSwitch.all.keys).to match_array(%w[foo bar])
      expect(ActiveSwitch.all.values.map(&:threshold_seconds)).to match_array([10, 20])
    end
  end

  describe ".active" do
    it "returns a hash of only active status" do
      ActiveSwitch.report(:foo)
      statuses = ActiveSwitch.active

      expect(statuses.length).to eq(1)
      expect(statuses["foo"].name).to eq("foo")
    end
  end

  describe ".inactive" do
    it "returns a hash of only inactive status" do
      ActiveSwitch.report(:foo)
      statuses = ActiveSwitch.inactive

      expect(statuses.length).to eq(1)
      expect(statuses["bar"].name).to eq("bar")
    end
  end

  describe ".report_on_inactive" do
    it "reports on inactive statuses to aid initial deployments" do
      foo_epoch_seconds = Time.now.to_i - 5
      redis.hset(storage_key, :foo, foo_epoch_seconds)
      ActiveSwitch.report_on_inactive
      expect(ActiveSwitch.inactive).to eq({})
      expect(ActiveSwitch.status(:foo).last_reported_at.to_i).to eq(foo_epoch_seconds)
    end
  end
end
