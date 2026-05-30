require "rails_helper"

RSpec.describe Strava::TokenRefresher do
  let(:user) { create(:user, :with_strava) }
  subject(:refresher) { described_class.new(user) }

  describe "#call" do
    context "when token is still valid" do
      before { user.update!(strava_token_expires_at: 1.hour.from_now) }

      it "returns current access token without calling Strava API" do
        expect(Net::HTTP).not_to receive(:post_form)
        result = refresher.call
        expect(result).to eq(user.strava_access_token)
      end
    end

    context "when token is expired" do
      before do
        user.update!(strava_token_expires_at: 1.hour.ago)
        allow(ENV).to receive(:fetch).with("STRAVA_CLIENT_ID").and_return("test_client_id")
        allow(ENV).to receive(:fetch).with("STRAVA_CLIENT_SECRET").and_return("test_client_secret")
      end

      let(:new_expires_at) { 6.hours.from_now.to_i }
      let(:strava_response_body) do
        {
          access_token:  "new_access_token",
          refresh_token: "new_refresh_token",
          expires_at:    new_expires_at
        }.to_json
      end

      context "when Strava API returns success" do
        before do
          stub_request(:post, Strava::TokenRefresher::STRAVA_TOKEN_URL)
            .to_return(status: 200, body: strava_response_body, headers: { "Content-Type" => "application/json" })
        end

        it "returns the new access token" do
          result = refresher.call
          expect(result).to eq("new_access_token")
        end

        it "updates user tokens" do
          refresher.call
          user.reload
          expect(user.strava_access_token).to eq("new_access_token")
          expect(user.strava_refresh_token).to eq("new_refresh_token")
          expect(user.strava_token_expires_at.to_i).to eq(new_expires_at)
        end
      end

      context "when Strava API returns an error" do
        before do
          stub_request(:post, Strava::TokenRefresher::STRAVA_TOKEN_URL)
            .to_return(status: 401, body: '{"error": "invalid_token"}')
        end

        it "raises RefreshError" do
          expect { refresher.call }.to raise_error(Strava::TokenRefresher::RefreshError)
        end
      end
    end
  end
end
