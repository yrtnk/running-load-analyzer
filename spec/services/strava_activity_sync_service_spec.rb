require "rails_helper"

RSpec.describe StravaActivitySyncService do
  let(:user) { create(:user, :with_strava) }
  subject(:service) { described_class.new(user) }

  def build_raw_activity(id:, sport_type: "Run", distance: 10_000.0, moving_time: 3600, elapsed_time: 3700)
    instance_double(
      Strava::Models::SummaryActivity,
      id: id,
      name: "Morning Run #{id}",
      sport_type: sport_type,
      distance: distance,
      moving_time: moving_time,
      elapsed_time: elapsed_time,
      average_heartrate: 145.0,
      max_heartrate: 165,
      start_date_local: Time.zone.now
    )
  end

  describe "#call" do
    context "when user has no strava token" do
      before { user.update!(strava_access_token: nil, strava_refresh_token: nil) }

      it "returns failure result" do
        result = service.call
        expect(result.success?).to be false
        expect(result.error_message).to eq("Stravaと連携されていません")
      end
    end

    context "when token is valid" do
      let(:api_client) { instance_double(Strava::Api::Client) }

      before do
        allow(Strava::Api::Client).to receive(:new).and_return(api_client)
        allow(api_client).to receive(:athlete_activities).and_return([
          build_raw_activity(id: 111),
          build_raw_activity(id: 222)
        ])
      end

      it "returns success result with imported count" do
        result = service.call
        expect(result.success?).to be true
        expect(result.imported_count).to eq(2)
      end

      it "saves activities to database" do
        expect { service.call }.to change(Activity, :count).by(2)
      end
    end

    context "when activities already exist (duplicate prevention)" do
      let(:api_client) { instance_double(Strava::Api::Client) }

      before do
        create(:activity, user: user, strava_activity_id: 111)
        allow(Strava::Api::Client).to receive(:new).and_return(api_client)
        allow(api_client).to receive(:athlete_activities).and_return([
          build_raw_activity(id: 111),
          build_raw_activity(id: 222)
        ])
      end

      it "skips existing activities" do
        expect { service.call }.to change(Activity, :count).by(1)
      end

      it "returns only newly imported count" do
        result = service.call
        expect(result.imported_count).to eq(1)
      end
    end

    context "when activities include non-Run types" do
      let(:api_client) { instance_double(Strava::Api::Client) }

      before do
        allow(Strava::Api::Client).to receive(:new).and_return(api_client)
        allow(api_client).to receive(:athlete_activities).and_return([
          build_raw_activity(id: 111, sport_type: "Run"),
          build_raw_activity(id: 222, sport_type: "Ride"),
          build_raw_activity(id: 333, sport_type: "Swim")
        ])
      end

      it "imports only Run activities" do
        expect { service.call }.to change(Activity, :count).by(1)
      end
    end

    context "when token is expired" do
      let(:oauth_client) { instance_double(Strava::OAuth::Client) }
      let(:api_client) { instance_double(Strava::Api::Client) }
      let(:token_response) do
        instance_double(
          Strava::Models::Token,
          access_token: "new_access_token",
          refresh_token: "new_refresh_token",
          expires_at: 1.hour.from_now.to_i
        )
      end

      before do
        user.update!(strava_token_expires_at: 1.hour.ago)
        allow(ENV).to receive(:fetch).with("STRAVA_CLIENT_ID").and_return("client_id")
        allow(ENV).to receive(:fetch).with("STRAVA_CLIENT_SECRET").and_return("client_secret")
        allow(Strava::OAuth::Client).to receive(:new).and_return(oauth_client)
        allow(oauth_client).to receive(:oauth_token).and_return(token_response)
        allow(Strava::Api::Client).to receive(:new).and_return(api_client)
        allow(api_client).to receive(:athlete_activities).and_return([])
      end

      it "refreshes the token before fetching" do
        service.call
        user.reload
        expect(user.strava_access_token).to eq("new_access_token")
      end
    end
  end
end
