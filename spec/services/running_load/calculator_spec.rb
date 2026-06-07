require "rails_helper"

RSpec.describe RunningLoad::Calculator do
  # target_paceのstubに使う固定ペース値（秒/km）
  # easy:360 > marathon:300 > threshold:270 > cv:255 > interval:240 > repetition:210
  let(:target_time) do
    instance_double(
      TargetTime,
      target_pace: nil
    ).tap do |tt|
      allow(tt).to receive(:target_pace).with(:easy).and_return(360)
      allow(tt).to receive(:target_pace).with(:marathon).and_return(300)
      allow(tt).to receive(:target_pace).with(:threshold).and_return(270)
      allow(tt).to receive(:target_pace).with(:cv).and_return(255)
      allow(tt).to receive(:target_pace).with(:interval).and_return(240)
      allow(tt).to receive(:target_pace).with(:repetition).and_return(210)
    end
  end

  def build_activity(average_pace:, moving_time: 3600)
    instance_double(Activity, average_pace: average_pace, moving_time: moving_time)
  end

  describe "#call" do
    context "when target_time is nil" do
      it "returns nil" do
        activity = build_activity(average_pace: 270)
        result = described_class.new(activity, nil).call
        expect(result).to be_nil
      end
    end

    context "when average_pace is nil" do
      it "returns nil" do
        activity = instance_double(Activity, average_pace: nil, moving_time: 3600)
        result = described_class.new(activity, target_time).call
        expect(result).to be_nil
      end
    end

    context "when pace is slower than easy pace (>= easy_pace)" do
      it "uses easy load factor (0.2)" do
        activity = build_activity(average_pace: 400, moving_time: 3600)
        result = described_class.new(activity, target_time).call
        # 0.2 * 3600 / 48 / 60 * 100 = 25.0
        expect(result).to eq(25.0)
      end
    end

    context "when pace equals easy pace boundary" do
      it "uses easy load factor" do
        activity = build_activity(average_pace: 360, moving_time: 3600)
        result = described_class.new(activity, target_time).call
        expect(result).to eq(25.0)
      end
    end

    context "when pace is faster than repetition pace (<= repetition_pace)" do
      it "uses repetition load factor (1.5)" do
        activity = build_activity(average_pace: 180, moving_time: 3600)
        result = described_class.new(activity, target_time).call
        # 1.5 * 3600 / 48 / 60 * 100 = 187.5
        expect(result).to eq(187.5)
      end
    end

    context "when pace equals repetition pace boundary" do
      it "uses repetition load factor" do
        activity = build_activity(average_pace: 210, moving_time: 3600)
        result = described_class.new(activity, target_time).call
        expect(result).to eq(187.5)
      end
    end

    context "when pace equals threshold pace (基準値テスト)" do
      it "returns 100.0 for 60 minutes at threshold pace" do
        activity = build_activity(average_pace: 270, moving_time: 3600)
        result = described_class.new(activity, target_time).call
        # 0.8 * 3600 / 48 / 60 * 100 = 100.0
        expect(result).to eq(100.0)
      end
    end

    context "when pace is between easy and marathon (線形補間)" do
      it "interpolates load factor correctly" do
        # pace=330: easy(360,0.2)〜marathon(300,0.4)の中間
        # slope = (0.4 - 0.2) / (300 - 360) = -1/300
        # factor = 0.2 + (-1/300) * (330 - 360) = 0.2 + 0.1 = 0.3
        # score = 0.3 * 3600 / 48 / 60 * 100 = 37.5
        activity = build_activity(average_pace: 330, moving_time: 3600)
        result = described_class.new(activity, target_time).call
        expect(result).to eq(37.5)
      end
    end

    context "when pace is between threshold and cv" do
      it "interpolates load factor correctly" do
        # pace=262.5: threshold(270,0.8)〜cv(255,1.0)の中間
        # slope = (1.0 - 0.8) / (255 - 270) = 0.2 / (-15) = -1/75
        # factor = 0.8 + (-1/75) * (262.5 - 270) = 0.8 + 0.1 = 0.9
        # score = 0.9 * 3600 / 48 / 60 * 100 = 112.5
        activity = build_activity(average_pace: 262.5, moving_time: 3600)
        result = described_class.new(activity, target_time).call
        expect(result).to eq(112.5)
      end
    end

    context "with different moving_time" do
      it "scales load_score proportionally to duration" do
        # threshold pace, 30分 → 50.0
        activity = build_activity(average_pace: 270, moving_time: 1800)
        result = described_class.new(activity, target_time).call
        expect(result).to eq(50.0)
      end
    end
  end

  describe "#category" do
    context "when target_time is nil" do
      it "returns nil" do
        activity = build_activity(average_pace: 270)
        expect(described_class.new(activity, nil).category).to be_nil
      end
    end

    context "when average_pace is nil" do
      it "returns nil" do
        activity = instance_double(Activity, average_pace: nil, moving_time: 3600)
        expect(described_class.new(activity, target_time).category).to be_nil
      end
    end

    context "when pace is slower than easy pace" do
      it "returns 'easy'" do
        activity = build_activity(average_pace: 400)
        expect(described_class.new(activity, target_time).category).to eq("easy")
      end
    end

    context "when pace equals easy pace boundary" do
      it "returns 'easy'" do
        activity = build_activity(average_pace: 360)
        expect(described_class.new(activity, target_time).category).to eq("easy")
      end
    end

    context "when pace is faster than repetition pace" do
      it "returns 'repetition'" do
        activity = build_activity(average_pace: 180)
        expect(described_class.new(activity, target_time).category).to eq("repetition")
      end
    end

    context "when pace equals repetition pace boundary" do
      it "returns 'repetition'" do
        activity = build_activity(average_pace: 210)
        expect(described_class.new(activity, target_time).category).to eq("repetition")
      end
    end

    context "when pace equals threshold pace" do
      it "returns 'threshold'" do
        activity = build_activity(average_pace: 270)
        expect(described_class.new(activity, target_time).category).to eq("threshold")
      end
    end

    context "when pace is between easy and marathon (closer to easy)" do
      it "returns 'easy'" do
        # easy=360, marathon=300, 境界=330
        # pace=340 → |340-300|=40 > |340-360|=20 → easy
        activity = build_activity(average_pace: 340)
        expect(described_class.new(activity, target_time).category).to eq("easy")
      end
    end

    context "when pace is between easy and marathon (closer to marathon)" do
      it "returns 'marathon'" do
        # easy=360, marathon=300, 境界=330
        # pace=310 → |310-300|=10 < |310-360|=50 → marathon
        activity = build_activity(average_pace: 310)
        expect(described_class.new(activity, target_time).category).to eq("marathon")
      end
    end

    context "when pace is between threshold and cv (closer to cv)" do
      it "returns 'cv'" do
        # threshold=270, cv=255, 境界=262.5
        # pace=258 → |258-255|=3 < |258-270|=12 → cv
        activity = build_activity(average_pace: 258)
        expect(described_class.new(activity, target_time).category).to eq("cv")
      end
    end
  end
end
