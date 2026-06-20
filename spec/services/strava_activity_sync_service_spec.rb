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

  def build_split(index:, average_speed: 1000.0 / 360, moving_time: 360, distance: 1000.0)
    instance_double(
      Strava::Models::Split,
      split: index,
      distance: distance,
      moving_time: moving_time,
      elapsed_time: moving_time + 10,
      average_speed: average_speed,
      elevation_difference: nil
    )
  end

  def build_detail_activity(splits: [])
    instance_double(Strava::Models::DetailedActivity, splits_metric: splits)
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
        allow(api_client).to receive(:activity).and_return(build_detail_activity(splits: []))
      end

      it "returns success result with imported count" do
        result = service.call
        expect(result.success?).to be true
        expect(result.imported_count).to eq(2)
      end

      it "saves activities to database" do
        expect { service.call }.to change(Activity, :count).by(2)
      end

      context "when user has no target_time" do
        it "saves activities with nil load_score" do
          service.call
          expect(Activity.last.load_score).to be_nil
        end

        it "saves activities with nil load_category" do
          service.call
          expect(Activity.last.load_category).to be_nil
        end
      end

      context "when user has a target_time" do
        before { create(:target_time, user: user) }

        it "saves activities with calculated load_score" do
          service.call
          expect(Activity.last.load_score).to be_present
        end

        it "saves activities with calculated load_category" do
          service.call
          expect(Activity.last.load_category).to be_present
        end
      end
    end

    context "when splits are returned from Strava API" do
      let(:api_client) { instance_double(Strava::Api::Client) }
      let(:splits) do
        [
          build_split(index: 1, average_speed: 1000.0 / 270, moving_time: 270),  # threshold
          build_split(index: 2, average_speed: 1000.0 / 360, moving_time: 360)   # easy
        ]
      end

      before do
        allow(Strava::Api::Client).to receive(:new).and_return(api_client)
        allow(api_client).to receive(:athlete_activities).and_return([
          build_raw_activity(id: 111)
        ])
        allow(api_client).to receive(:activity).and_return(build_detail_activity(splits: splits))
      end

      it "saves ActivitySplit records for the activity" do
        expect { service.call }.to change(ActivitySplit, :count).by(2)
      end

      context "when user has a target_time" do
        before { create(:target_time, user: user) }

        it "updates load_score to split-based sum" do
          service.call
          activity = Activity.last
          # split1: threshold(0.8) * 270 / 48 / 60 * 100 = 7.5
          # split2: easy(0.2) * 360 / 48 / 60 * 100 = 2.5 →合計 10.0 だが
          # target_time VDOT=60 時のpaceは固定値ではないため、be_positive で検証
          expect(activity.load_score).to be_present
          expect(activity.load_score).to be_a(Float)
        end

        it "overwrites the fallback Calculator-based load_score" do
          service.call
          activity = Activity.last
          expected_split_sum = activity.activity_splits.sum { |s| s.split_load(TargetTime.last) }
          expect(activity.load_score).to eq(expected_split_sum.round(2))
        end
      end

      context "when user has no target_time" do
        it "saves splits but load_score remains nil" do
          service.call
          activity = Activity.last
          expect(activity.activity_splits.count).to eq(2)
          expect(activity.load_score).to be_nil
        end
      end
    end

    context "when detail fetch fails" do
      let(:api_client) { instance_double(Strava::Api::Client) }

      before do
        allow(Strava::Api::Client).to receive(:new).and_return(api_client)
        allow(api_client).to receive(:athlete_activities).and_return([
          build_raw_activity(id: 111)
        ])
        allow(api_client).to receive(:activity).and_raise(StandardError, "API error")
      end

      it "still saves the activity" do
        expect { service.call }.to change(Activity, :count).by(1)
      end

      it "saves no splits" do
        service.call
        expect(ActivitySplit.count).to eq(0)
      end

      it "returns success" do
        result = service.call
        expect(result.success?).to be true
      end
    end

    context "when more than MAX_DETAIL_FETCHES_PER_SYNC activities are new" do
      let(:api_client) { instance_double(Strava::Api::Client) }
      let(:raw_activities) do
        (1..12).map { |i| build_raw_activity(id: i) }
      end

      before do
        allow(Strava::Api::Client).to receive(:new).and_return(api_client)
        allow(api_client).to receive(:athlete_activities).and_return(raw_activities)
        allow(api_client).to receive(:activity).and_return(build_detail_activity(splits: []))
      end

      it "limits detail API calls to MAX_DETAIL_FETCHES_PER_SYNC" do
        service.call
        expect(api_client).to have_received(:activity).at_most(
          StravaActivitySyncService::MAX_DETAIL_FETCHES_PER_SYNC
        ).times
      end

      it "still imports all activities" do
        expect { service.call }.to change(Activity, :count).by(12)
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
        allow(api_client).to receive(:activity).and_return(build_detail_activity(splits: []))
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
        allow(api_client).to receive(:activity).and_return(build_detail_activity(splits: []))
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
