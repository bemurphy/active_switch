require "spec_helper"

RSpec.describe ActiveSwitch::Status do
  it "initializes with name, last_seen_at, and threshold_seconds" do
    status = ActiveSwitch::Status.new(name: :spec_name, last_seen_at: 42,
                                      threshold_seconds: 99)

    expect(status.name).to eq("spec_name")
    expect(status.last_seen_at).to eq(Time.at(42))
    expect(status.threshold_seconds).to eq(99)
  end

  it "can cast the last_seen_at from a string epoch seconds" do
    status = ActiveSwitch::Status.new(name: :spec_name, last_seen_at: 123,
                                      threshold_seconds: 99)

    expect(status.last_seen_at).to eq(Time.at(123))
  end

  it "can cast the last_seen_at from time instance" do
    time = Time.now

    status = ActiveSwitch::Status.new(name: :spec_name, last_seen_at: time,
                                      threshold_seconds: 99)

    expect(status.last_seen_at).to be_a(Time)
    expect(status.last_seen_at.to_i).to eq(time.to_i)
  end

  it "is active when the last seen at is within the threshold" do
    status = ActiveSwitch::Status.new(name: :spec_name, last_seen_at: Time.now - 58,
                                      threshold_seconds: 60)

    expect(status).to be_active
    expect(status).not_to be_inactive
  end

  it "is inactive when the last seen at is outsite the threshold" do
    status = ActiveSwitch::Status.new(name: :spec_name, last_seen_at: Time.now - 61,
                                      threshold_seconds: 60)

    expect(status).not_to be_active
    expect(status).to be_inactive
  end

  it "is inactive when the last seen at is nil" do
    status = ActiveSwitch::Status.new(name: :spec_name, last_seen_at: nil,
                                      threshold_seconds: 60)

    expect(status).not_to be_active
    expect(status).to be_inactive
  end

  it "has a state of ACTIVE when active" do
    status = ActiveSwitch::Status.new(name: :spec_name, last_seen_at: Time.now - 58,
                                      threshold_seconds: 60)

    expect(status.state).to eq("ACTIVE")
  end

  it "has a state of INACTIVE when inactive" do
    status = ActiveSwitch::Status.new(name: :spec_name, last_seen_at: Time.now - 61,
                                      threshold_seconds: 60)

    expect(status.state).to eq("INACTIVE")
  end
end
