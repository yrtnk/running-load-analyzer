require "rails_helper"

RSpec.describe RunningLoad::WeeklyAggregator do
  let(:user) { create(:user) }
  let(:aggregator) { described_class.new(user) }

  def create_run(days_ago:, load_score:)
    create(:activity,
           user: user,
           activity_type: "Run",
           start_date: days_ago.days.ago,
           load_score: load_score)
  end

  describe "#current_stl" do
    it "returns average daily load over last 7 days" do
      create_run(days_ago: 0, load_score: 70.0)
      create_run(days_ago: 3, load_score: 70.0)
      create_run(days_ago: 6, load_score: 70.0)
      # total=210, days=7 → 30.0
      expect(aggregator.current_stl).to eq(30.0)
    end

    it "excludes activities older than 7 days" do
      create_run(days_ago: 7, load_score: 999.0)
      expect(aggregator.current_stl).to eq(0.0)
    end

    it "excludes activities with nil load_score" do
      create(:activity, user: user, activity_type: "Run", start_date: 1.day.ago, load_score: nil)
      expect(aggregator.current_stl).to eq(0.0)
    end

    it "excludes non-Run activities" do
      create(:activity, user: user, activity_type: "Ride", start_date: 1.day.ago, load_score: 100.0)
      expect(aggregator.current_stl).to eq(0.0)
    end
  end

  describe "#current_ltl" do
    it "returns average daily load over last 30 days" do
      create_run(days_ago: 0, load_score: 60.0)
      create_run(days_ago: 29, load_score: 60.0)
      # total=120, days=30 → 4.0
      expect(aggregator.current_ltl).to eq(4.0)
    end

    it "excludes activities older than 30 days" do
      create_run(days_ago: 30, load_score: 999.0)
      expect(aggregator.current_ltl).to eq(0.0)
    end
  end

  describe "#injury_risk?" do
    it "returns true when STL exceeds LTL by more than 120%" do
      # STL用: 7日以内に大量の負荷
      7.times { |i| create_run(days_ago: i, load_score: 100.0) }
      # LTLはSTLより低い状態をつくる（過去8〜30日に少量の負荷）
      (8..29).each { |i| create_run(days_ago: i, load_score: 5.0) }

      expect(aggregator.injury_risk?).to be(true)
    end

    it "returns false when both STL and LTL are zero" do
      expect(aggregator.injury_risk?).to be(false)
    end

    it "returns false when STL is within 120% of LTL" do
      30.times { |i| create_run(days_ago: i, load_score: 50.0) }
      expect(aggregator.injury_risk?).to be(false)
    end
  end

  describe "#call" do
    it "returns a hash with required keys" do
      result = aggregator.call
      expect(result).to include(
        :chart_data, :current_stl, :current_ltl, :stl_ltl_diff, :injury_risk
      )
    end

    it "chart_data contains labels, weekly_totals, ltl_values" do
      result = aggregator.call
      chart = result[:chart_data]
      expect(chart[:labels].length).to eq(12)
      expect(chart[:weekly_totals].length).to eq(12)
      expect(chart[:ltl_values].length).to eq(12)
    end

    it "weekly_totals sums load_score for each week" do
      create_run(days_ago: 0, load_score: 80.0)
      create_run(days_ago: 1, load_score: 60.0)
      result = aggregator.call
      # 最新週（index末尾）に 140.0 が入る
      expect(result[:chart_data][:weekly_totals].last).to eq(140.0)
    end
  end
end
