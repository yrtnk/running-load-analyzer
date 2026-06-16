require "rails_helper"

RSpec.describe RunningLoad::LoadFactor do
  # target_paceのstubに使う固定ペース値（秒/km）
  # easy:360 > marathon:300 > threshold:270 > cv:255 > interval:240 > repetition:210
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

  describe ".factor_for_pace" do
    context "when target_time is nil" do
      it "returns nil" do
        expect(described_class.factor_for_pace(270, nil)).to be_nil
      end
    end

    context "when pace is nil" do
      it "returns nil" do
        expect(described_class.factor_for_pace(nil, target_time)).to be_nil
      end
    end

    context "when pace is slower than easy pace (>=easy)" do
      it "returns easy load factor (0.2)" do
        expect(described_class.factor_for_pace(400, target_time)).to eq(0.2)
        expect(described_class.factor_for_pace(360, target_time)).to eq(0.2)
      end
    end

    context "when pace is faster than repetition pace (<=repetition)" do
      it "returns repetition load factor (1.5)" do
        expect(described_class.factor_for_pace(180, target_time)).to eq(1.5)
        expect(described_class.factor_for_pace(210, target_time)).to eq(1.5)
      end
    end

    context "when pace equals threshold pace" do
      it "returns threshold load factor (0.8)" do
        expect(described_class.factor_for_pace(270, target_time)).to eq(0.8)
      end
    end

    context "when pace is between easy and marathon (interpolation)" do
      it "interpolates correctly" do
        # pace=330: slope = (0.4 - 0.2) / (300 - 360) = -1/300
        # factor = 0.2 + (-1/300) * (330 - 360) = 0.3
        expect(described_class.factor_for_pace(330, target_time)).to be_within(1e-9).of(0.3)
      end
    end
  end

  describe ".score" do
    context "when pace or target_time is nil" do
      it "returns nil" do
        expect(described_class.score(pace: nil, duration: 3600, target_time: target_time)).to be_nil
        expect(described_class.score(pace: 270, duration: 3600, target_time: nil)).to be_nil
      end
    end

    context "with threshold pace for 60 minutes" do
      it "returns 100.0 (= STANDARD_LOAD)" do
        # threshold: factor=0.8, STANDARD_LOAD=48
        # 0.8 * 3600 / 48 / 60 * 100 = 100.0
        result = described_class.score(pace: 270, duration: 3600, target_time: target_time)
        expect(result).to be_within(1e-9).of(100.0)
      end
    end

    context "with easy pace for 30 minutes" do
      it "scales proportionally" do
        # 0.2 * 1800 / 48 / 60 * 100 = 12.5
        result = described_class.score(pace: 400, duration: 1800, target_time: target_time)
        expect(result).to be_within(1e-9).of(12.5)
      end
    end
  end

  describe ".category_for_pace" do
    context "when target_time is nil or pace is nil" do
      it "returns nil" do
        expect(described_class.category_for_pace(270, nil)).to be_nil
        expect(described_class.category_for_pace(nil, target_time)).to be_nil
      end
    end

    context "when pace is slower than easy" do
      it "returns :easy" do
        expect(described_class.category_for_pace(400, target_time)).to eq(:easy)
      end
    end

    context "when pace is faster than repetition" do
      it "returns :repetition" do
        expect(described_class.category_for_pace(180, target_time)).to eq(:repetition)
      end
    end

    context "when pace is between easy and marathon (closer to easy)" do
      it "returns :easy" do
        # pace=340: |340-360|=20 < |340-300|=40
        expect(described_class.category_for_pace(340, target_time)).to eq(:easy)
      end
    end

    context "when pace is between easy and marathon (closer to marathon)" do
      it "returns :marathon" do
        # pace=310: |310-300|=10 < |310-360|=50
        expect(described_class.category_for_pace(310, target_time)).to eq(:marathon)
      end
    end
  end
end
