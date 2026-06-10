class StravaActivitySyncService
  Result = Struct.new(:success?, :imported_count, :error_message)

  def initialize(user)
    @user = user
  end

  def call
    return Result.new(false, 0, "Stravaと連携されていません") unless strava_connected?

    refresh_token_if_expired!
    activities = fetch_activities
    imported_count = save_activities(activities)
    Result.new(true, imported_count, nil)
  rescue StandardError => e
    Rails.logger.error "StravaActivitySyncService Error: #{e.message}"
    Result.new(false, 0, e.message)
  end

  private

  def strava_connected?
    @user.strava_access_token.present?
  end

  def refresh_token_if_expired!
    return unless @user.strava_token_expired?

    oauth_client = Strava::OAuth::Client.new(
      client_id: ENV.fetch("STRAVA_CLIENT_ID"),
      client_secret: ENV.fetch("STRAVA_CLIENT_SECRET")
    )
    response = oauth_client.oauth_token(
      refresh_token: @user.strava_refresh_token,
      grant_type: "refresh_token"
    )
    @user.update!(
      strava_access_token: response.access_token,
      strava_refresh_token: response.refresh_token,
      strava_token_expires_at: Time.zone.at(response.expires_at)
    )
  end

  def fetch_activities
    client = Strava::Api::Client.new(access_token: @user.strava_access_token)
    client.athlete_activities
  end

  def save_activities(activities)
    target_time = @user.target_times.order(revised_at: :desc).first
    count = 0
    activities.each do |raw|
      next unless raw.sport_type == "Run"
      next if Activity.exists?(user_id: @user.id, strava_activity_id: raw.id)

      Activity.create!(build_activity_attrs(raw, target_time))
      count += 1
    end
    count
  end

  def build_activity_attrs(raw, target_time)
    distance_km = raw.distance.to_f / 1000.0
    pace = distance_km.positive? ? raw.moving_time.to_f / distance_km : nil

    activity = Activity.new(average_pace: pace, moving_time: raw.moving_time)
    calculator = RunningLoad::Calculator.new(activity, target_time)

    {
      user_id: @user.id,
      strava_activity_id: raw.id,
      name: raw.name,
      distance: raw.distance,
      moving_time: raw.moving_time,
      elapsed_time: raw.elapsed_time,
      average_heartrate: raw.average_heartrate,
      max_heartrate: raw.max_heartrate,
      average_pace: pace,
      start_date: raw.start_date_local,
      activity_type: raw.sport_type,
      load_score: calculator.call,
      load_category: calculator.category
    }
  end
end
