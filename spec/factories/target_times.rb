FactoryBot.define do
  factory :target_time do
    association :user
    # VDOT 60 相当 (3:00:00 = 10800秒) に近い値
    target_marathon_time { 10800 }
    target_vdot          { 60.0 }
    revised_at           { Date.today }
  end
end
