class Activity < ApplicationRecord
  belongs_to :user

  validates :strava_activity_id, presence: true, uniqueness: { scope: :user_id }
  validates :name, presence: true

  scope :recent, -> { order(start_date: :desc) }
  scope :runs, -> { where(activity_type: "Run") }

  LOW_LOAD = 20
  MIDDLE_LOAD = 50
  HIGH_LOAD = 80

  def distance_km
    return 0.0 unless distance
    (distance / 1000.0).round(2)
  end

  def pace_display
    return "-" unless average_pace&.positive?
    minutes = (average_pace / 60).floor
    seconds = (average_pace % 60).round
    format("%d'%02d\"", minutes, seconds)
  end

  def load_score_color
    return "text-gray-400" if load_score.nil?

    if load_score <= LOW_LOAD
      "text-blue-500"
    elsif load_score <= MIDDLE_LOAD
      "text-yellow-400"
    elsif load_score <= HIGH_LOAD
      "text-yellow-600"
    else
      "text-red-600"
    end
  end
end
