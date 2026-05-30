module Strava
  class TokenRefresher
    STRAVA_TOKEN_URL = "https://www.strava.com/oauth/token"

    class RefreshError < StandardError; end

    def initialize(user)
      @user = user
    end

    def call
      return @user.strava_access_token unless @user.strava_token_expired?

      refresh!
      @user.strava_access_token
    end

    private

    def refresh!
      response = post_refresh_request

      unless response.is_a?(Net::HTTPSuccess)
        raise RefreshError, "Strava token refresh failed (HTTP #{response.code})"
      end

      data = JSON.parse(response.body)
      @user.update!(
        strava_access_token:     data["access_token"],
        strava_refresh_token:    data["refresh_token"],
        strava_token_expires_at: Time.zone.at(data["expires_at"])
      )
    end

    def post_refresh_request
      uri = URI(STRAVA_TOKEN_URL)
      Net::HTTP.post_form(uri, refresh_params)
    end

    def refresh_params
      {
        client_id:     ENV.fetch("STRAVA_CLIENT_ID"),
        client_secret: ENV.fetch("STRAVA_CLIENT_SECRET"),
        grant_type:    "refresh_token",
        refresh_token: @user.strava_refresh_token
      }
    end
  end
end
