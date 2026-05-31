class Activity < ApplicationRecord
  belongs_to :user

  validates :strava_activity_id, presence: true, uniqueness: { scope: :user_id }
  validates :name, presence: true

  scope :recent, -> { order(start_date: :desc) }
  scope :runs, -> { where(activity_type: "Run") }

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
end
