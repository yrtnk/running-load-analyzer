require "rails_helper"

RSpec.describe User, type: :model do
  describe ".from_omniauth" do
    let(:auth) do
      OmniAuth::AuthHash.new(
        uid: "12345",
        credentials: {
          token:      "new_access_token",
          refresh_token: "new_refresh_token",
          expires_at: 1.hour.from_now.to_i
        }
      )
    end

    context "when user does not exist" do
      it "creates a new user with strava credentials" do
        user = User.from_omniauth(auth)
        expect(user).to be_persisted
        expect(user.strava_uid).to eq("12345")
        expect(user.strava_access_token).to eq("new_access_token")
        expect(user.strava_refresh_token).to eq("new_refresh_token")
      end
    end

    context "when user already exists" do
      let!(:existing_user) { create(:user, :with_strava, strava_uid: "12345") }

      it "updates the existing user tokens" do
        user = User.from_omniauth(auth)
        expect(user.id).to eq(existing_user.id)
        expect(user.strava_access_token).to eq("new_access_token")
      end
    end
  end

  describe "#strava_token_expired?" do
    context "when token expires in the future" do
      let(:user) { build(:user, :with_strava, strava_token_expires_at: 1.hour.from_now) }

      it { expect(user.strava_token_expired?).to be false }
    end

    context "when token has expired" do
      let(:user) { build(:user, :with_strava, strava_token_expires_at: 1.hour.ago) }

      it { expect(user.strava_token_expired?).to be true }
    end

    context "when expires_at is nil" do
      let(:user) { build(:user, :with_strava, strava_token_expires_at: nil) }

      it { expect(user.strava_token_expired?).to be false }
    end
  end

  describe "#email_required?" do
    context "for Strava user (no email)" do
      let(:user) { build(:user, :with_strava) }

      it "does not require email" do
        expect(user.email_required?).to be false
      end
    end

    context "for regular user" do
      let(:user) { build(:user) }

      it "requires email" do
        expect(user.email_required?).to be true
      end
    end
  end

  describe "#password_required?" do
    context "for Strava user" do
      let(:user) { build(:user, :with_strava) }

      it "does not require password" do
        expect(user.password_required?).to be false
      end
    end

    context "for regular user" do
      let(:user) { build(:user) }

      it "requires password" do
        expect(user.password_required?).to be true
      end
    end
  end
end
