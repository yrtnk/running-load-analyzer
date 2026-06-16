FactoryBot.define do
  factory :activity_split do
    association :activity
    sequence(:split_index) { |n| n }
    distance { 1000.0 }
    moving_time { 300 }
    elapsed_time { 310 }
    average_speed { 1000.0 / 300 }  # 5分/km = 3.333... m/s
    elevation_difference { nil }
  end
end
