class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def strava
    @user = User.from_omniauth(request.env["omniauth.auth"])
    sign_in_and_redirect @user, event: :authentication
    set_flash_message(:notice, :success, kind: "Strava") if is_navigational_format?
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Strava OAuth failed: #{e.message}")
    redirect_to root_path, alert: "Strava認証に失敗しました"
  end

  def failure
    redirect_to root_path, alert: "Strava認証がキャンセルされました"
  end
end
