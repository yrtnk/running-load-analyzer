require "rails_helper"

RSpec.describe Activity, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { build(:activity) }

    it { is_expected.to validate_presence_of(:strava_activity_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:strava_activity_id).scoped_to(:user_id) }
  end

  describe "#distance_km" do
    it "converts meters to km" do
      activity = build(:activity, distance: 10_000.0)
      expect(activity.distance_km).to eq(10.0)
    end

    it "returns 0 when distance is nil" do
      activity = build(:activity, distance: nil)
      expect(activity.distance_km).to eq(0.0)
    end
  end

  describe "#pace_display" do
    it "formats pace as minutes'seconds\"" do
      activity = build(:activity, average_pace: 360.0)
      expect(activity.pace_display).to eq("6'00\"")
    end

    it "returns dash when average_pace is nil" do
      activity = build(:activity, average_pace: nil)
      expect(activity.pace_display).to eq("-")
    end
  end

  describe "#load_score_color" do
    it "returns gray when load_score is nil" do
      activity = build(:activity, load_score: nil)
      expect(activity.load_score_color).to eq("text-gray-400")
    end

    it "returns blue for low load (<=20)" do
      activity = build(:activity, load_score: 15.0)
      expect(activity.load_score_color).to eq("text-blue-500")
    end

    it "returns blue at boundary (20)" do
      activity = build(:activity, load_score: 20.0)
      expect(activity.load_score_color).to eq("text-blue-500")
    end

    it "returns yellow for middle load (<=50)" do
      activity = build(:activity, load_score: 35.0)
      expect(activity.load_score_color).to eq("text-yellow-400")
    end

    it "returns dark yellow for high-middle load (<=80)" do
      activity = build(:activity, load_score: 65.0)
      expect(activity.load_score_color).to eq("text-yellow-600")
    end

    it "returns red for very high load (>80)" do
      activity = build(:activity, load_score: 95.0)
      expect(activity.load_score_color).to eq("text-red-600")
    end
  end
end
