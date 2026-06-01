FactoryBot.define do
  factory :activity do
    association :user
    sequence(:strava_activity_id) { |n| n }
    name { "Morning Run" }
    distance { 10_000.0 }
    moving_time { 3600 }
    elapsed_time { 3700 }
    average_heartrate { 145.0 }
    max_heartrate { 165 }
    average_pace { 360.0 }
    start_date { Time.zone.now }
    activity_type { "Run" }
    load_score { nil }
    load_category { nil }
  end
end
