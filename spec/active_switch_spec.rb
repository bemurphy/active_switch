require "spec_helper"

RSpec.describe ActiveSwitch do
  let(:redis) { ActiveSwitch.redis }
  let(:storage_key) { ActiveSwitch::STORAGE_KEY }

  before do
    ActiveSwitch.register("spec_name", 10)
  end

  it "has a version number" do
    expect(ActiveSwitch::VERSION).not_to be nil
  end

  describe ".register" do
    it "adds the name and threshold seconds to REGISTRATIONS" do
      expect(ActiveSwitch::REGISTRATIONS).to eq("spec_name" => 10)
    end

    it "casts a symbol name to a string" do
      expect(ActiveSwitch::REGISTRATIONS).to eq("spec_name" => 10)
    end

    it "raises AlreadyRegistered if a duplicate name is registered" do
      expect {
        ActiveSwitch.register(:spec_name, 10)
      }.to raise_error(ActiveSwitch::AlreadyRegistered)
    end
  end

  describe ".report" do
    it "stores an epoch seconds timestamp in redis when reporting" do
      ActiveSwitch.report(:spec_name)
      expect(redis.hget(storage_key, :spec_name).to_i).to be_within(1).of(Time.now.to_i)
    end
  end

  describe ".status" do
    it "retrives a status instance for the name" do
      redis.hset(storage_key, :spec_name, 42)
      status = ActiveSwitch.status(:spec_name)

      expect(status).to be_a(ActiveSwitch::Status)
      expect(status.name).to eq("spec_name")
      expect(status.threshold_seconds).to eq(10)
      expect(status.last_seen_at).to eq(Time.at(42))
    end

    it "can return a status when no last seen at is set" do
      status = ActiveSwitch.status(:spec_name)
      expect(status).to be_a(ActiveSwitch::Status)
    end
  end

  describe ".all" do
    it "returns a hash of status of all registered names" do
      ActiveSwitch.register(:foo, 77)
      ActiveSwitch.register(:bar, 99)

      expect(ActiveSwitch.all.keys).to match_array(%w[spec_name foo bar])
      expect(ActiveSwitch.all.values.map(&:threshold_seconds)).to match_array([10, 77, 99])
    end
  end

  describe ".active" do
    it "returns a hash of only active status" do
      ActiveSwitch.register(:other_spec_name, 10)
      ActiveSwitch.report(:spec_name)
      statuses = ActiveSwitch.active

      expect(statuses.length).to eq(1)
      expect(statuses["spec_name"].name).to eq("spec_name")
    end
  end

  describe ".inactive" do
    it "returns a hash of only inactive status" do
      ActiveSwitch.register(:other_spec_name, 10)
      ActiveSwitch.report(:spec_name)
      statuses = ActiveSwitch.inactive

      expect(statuses.length).to eq(1)
      expect(statuses["other_spec_name"].name).to eq("other_spec_name")
    end
  end
end
