require "rails_helper"

RSpec.describe TargetTime, type: :model do
  describe "validations" do
    subject { build(:target_time) }

    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:target_marathon_time) }
    it { is_expected.to validate_presence_of(:target_vdot) }
    it { is_expected.to validate_presence_of(:revised_at) }

    it "is invalid with duplicate revised_at for the same user" do
      user = create(:user)
      create(:target_time, user: user, revised_at: Date.today)
      duplicate = build(:target_time, user: user, revised_at: Date.today)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:revised_at]).to include(I18n.t("errors.messages.taken"))
    end

    it "allows same revised_at for different users" do
      create(:target_time, revised_at: Date.today)
      other = build(:target_time, revised_at: Date.today)
      expect(other).to be_valid
    end
  end

  describe "time decomposition" do
    let(:target_time) { build(:target_time, target_marathon_time: 10800) } # 3:00:00

    it "returns correct hours" do
      expect(target_time.target_marathon_hours).to eq(3)
    end

    it "returns correct minutes" do
      expect(target_time.target_marathon_minutes).to eq(0)
    end

    it "returns correct seconds" do
      expect(target_time.target_marathon_seconds).to eq(0)
    end
  end

  describe "virtual attribute setters" do
    let(:target_time) { TargetTime.new }

    it "composes target_marathon_time from hours/minutes/seconds" do
      target_time.target_marathon_hours   = 3
      target_time.target_marathon_minutes = 30
      target_time.target_marathon_seconds = 15
      expect(target_time.target_marathon_time).to eq(3 * 3600 + 30 * 60 + 15)
    end
  end

  describe "#calc_target_vdot" do
    context "when marathon time falls between VDOT 59 and 60 (9947s〜9805s)" do
      it "returns a vdot between 59 and 60" do
        tt = build(:target_time, target_marathon_time: 9876, target_vdot: 0.0)
        tt.calc_target_vdot
        expect(tt.target_vdot).to be > 59.0
        expect(tt.target_vdot).to be < 60.0
      end
    end

    context "when marathon time is exactly a table boundary (VDOT 60 = 9805s)" do
      it "returns vdot close to 60" do
        tt = build(:target_time, target_marathon_time: 9805, target_vdot: 0.0)
        tt.calc_target_vdot
        expect(tt.target_vdot).to be_within(1.0).of(60.0)
      end
    end

    context "when marathon time is faster than any table entry" do
      it "does not raise and returns a positive vdot" do
        tt = build(:target_time, target_marathon_time: 6000, target_vdot: 0.0)
        expect { tt.calc_target_vdot }.not_to raise_error
        expect(tt.target_vdot).to be > 0
      end
    end
  end

  describe "#target_pace" do
    # VDOT 60 相当 (9805s) での期待値は run_app 実データより
    let(:target_time) { build(:target_time, target_marathon_time: 9805, target_vdot: 60.0) }

    TargetTime::CATEGORIES.each do |category|
      it "returns a positive number for :#{category}" do
        expect(target_time.target_pace(category)).to be > 0
      end
    end

    it "easy pace is slower than marathon pace" do
      expect(target_time.target_pace(:easy)).to be > target_time.target_pace(:marathon)
    end

    it "marathon pace is slower than threshold pace" do
      expect(target_time.target_pace(:marathon)).to be > target_time.target_pace(:threshold)
    end

    it "threshold pace is slower than interval pace" do
      expect(target_time.target_pace(:threshold)).to be > target_time.target_pace(:interval)
    end

    it "interval pace is slower than repetition pace" do
      expect(target_time.target_pace(:interval)).to be > target_time.target_pace(:repetition)
    end

    context "when vdot is exactly on a table entry (VDOT 60)" do
      it "returns easy pace close to 289 (run_app実データ)" do
        expect(target_time.target_pace(:easy)).to be_within(5).of(289)
      end

      it "returns threshold pace close to 220 (run_app実データ)" do
        expect(target_time.target_pace(:threshold)).to be_within(5).of(220)
      end
    end

    context "when upper and lower vdot entries are unavailable (out of range)" do
      it "returns 0" do
        tt = build(:target_time, target_marathon_time: 1, target_vdot: 0.1)
        expect(tt.target_pace(:threshold)).to eq(0)
      end
    end
  end
end
