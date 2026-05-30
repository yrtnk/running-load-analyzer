class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:strava]

  encrypts :strava_access_token, :strava_refresh_token

  def self.from_omniauth(auth)
    find_or_initialize_by(strava_uid: auth.uid).tap do |user|
      user.email                   ||= "#{auth.uid}@strava.invalid"
      user.strava_access_token     = auth.credentials.token
      user.strava_refresh_token    = auth.credentials.refresh_token
      user.strava_token_expires_at = Time.zone.at(auth.credentials.expires_at)
      user.save!
    end
  end

  def strava_token_expired?
    strava_token_expires_at.present? && strava_token_expires_at <= Time.current
  end

  def email_required?
    super && strava_uid.blank?
  end

  def password_required?
    super && strava_uid.blank?
  end
end
