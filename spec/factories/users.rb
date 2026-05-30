FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }

    trait :with_strava do
      sequence(:strava_uid) { |n| "strava_#{n}" }
      strava_access_token     { "access_token_dummy" }
      strava_refresh_token    { "refresh_token_dummy" }
      strava_token_expires_at { 1.hour.from_now }
      email                   { "#{strava_uid}@strava.invalid" }
      password                { nil }
    end

    trait :strava_token_expired do
      with_strava
      strava_token_expires_at { 1.hour.ago }
    end
  end
end
