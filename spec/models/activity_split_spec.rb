require "rails_helper"

RSpec.describe ActivitySplit, type: :model do
  let(:target_time) do
    instance_double(TargetTime).tap do |tt|
      allow(tt).to receive(:target_pace).with(:easy).and_return(360)
      allow(tt).to receive(:target_pace).with(:marathon).and_return(300)
      allow(tt).to receive(:target_pace).with(:threshold).and_return(270)
      allow(tt).to receive(:target_pace).with(:cv).and_return(255)
      allow(tt).to receive(:target_pace).with(:interval).and_return(240)
      allow(tt).to receive(:target_pace).with(:repetition).and_return(210)
    end
  end

  describe "validations" do
    it "is valid with required attributes" do
      split = build(:activity_split)
      expect(split).to be_valid
    end

    it "is invalid without split_index" do
      split = build(:activity_split, split_index: nil)
      expect(split).not_to be_valid
    end

    it "is invalid without average_speed" do
      split = build(:activity_split, average_speed: nil)
      expect(split).not_to be_valid
    end
  end

  describe "#pace" do
    context "when average_speed is positive" do
      it "returns seconds per km" do
        split = build(:activity_split, average_speed: 1000.0 / 300)
        expect(split.pace).to be_within(0.01).of(300.0)
      end
    end

    context "when average_speed is zero or nil" do
      it "returns nil" do
        expect(build(:activity_split, average_speed: 0.0).pace).to be_nil
        expect(build(:activity_split, average_speed: nil).pace).to be_nil
      end
    end
  end

  describe "#split_load" do
    context "with threshold pace for 60 minutes" do
      it "returns 100.0 (same base as Calculator)" do
        # threshold pace: 270秒/km = 1000/270 m/s
        split = build(:activity_split, average_speed: 1000.0 / 270, moving_time: 3600)
        result = split.split_load(target_time)
        expect(result).to be_within(0.01).of(100.0)
      end
    end

    context "when target_time is nil" do
      it "returns 0.0 (treats as no load contribution)" do
        split = build(:activity_split)
        expect(split.split_load(nil)).to eq(0.0)
      end
    end

    context "when average_speed is zero (un-paced split)" do
      it "returns 0.0" do
        split = build(:activity_split, average_speed: 0.0)
        expect(split.split_load(target_time)).to eq(0.0)
      end
    end
  end
end
