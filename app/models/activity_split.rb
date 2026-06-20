class ActivitySplit < ApplicationRecord
  belongs_to :activity

  validates :split_index, presence: true, uniqueness: { scope: :activity_id }
  validates :distance, :moving_time, :elapsed_time, :average_speed, presence: true

  # average_speed (m/s) → pace (秒/km)
  def pace
    return nil unless average_speed&.positive?

    1000.0 / average_speed
  end

  def split_load(target_time)
    RunningLoad::LoadFactor.score(
      pace: pace,
      duration: moving_time,
      target_time: target_time
    ) || 0.0
  end
end
