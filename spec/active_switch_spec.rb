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
  end

  describe ".report" do
    it "stores an epoch seconds timestamp in redis when reporting" do
      ActiveSwitch.report(:foo)
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
      expect(status.last_seen_at).to eq(Time.at(42))
    end

    it "can return a status when no last seen at is set" do
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
end
