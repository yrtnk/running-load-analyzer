class TargetTime < ApplicationRecord
  belongs_to :user

  validates :target_marathon_time, presence: true,
            numericality: { only_integer: true, greater_than: 0 }
  validates :target_vdot, presence: true,
            numericality: { greater_than: 0 }
  validates :revised_at, presence: true
  validate  :revised_at_must_be_unique_per_user

  CATEGORIES = %i[easy marathon threshold cv interval repetition].freeze

  # 時/分/秒の仮想属性（フォーム入力用）
  def target_marathon_hours=(val)
    @target_marathon_hours = val.to_i
    update_target_marathon_time
  end

  def target_marathon_minutes=(val)
    @target_marathon_minutes = val.to_i
    update_target_marathon_time
  end

  def target_marathon_seconds=(val)
    @target_marathon_seconds = val.to_i
    update_target_marathon_time
  end

  def target_marathon_hours
    return 0 if target_marathon_time.blank?

    target_marathon_time / 3600
  end

  def target_marathon_minutes
    return 0 if target_marathon_time.blank?

    (target_marathon_time % 3600) / 60
  end

  def target_marathon_seconds
    return 0 if target_marathon_time.blank?

    target_marathon_time % 60
  end

  # マラソンタイムから target_vdot を線形補間で算出してセット・保存
  def calc_target_vdot
    lower = VdotTable.find_lower(target_marathon_time)
    upper = VdotTable.find_upper(target_marathon_time)

    if lower.nil? || upper.nil?
      self.target_vdot = (lower || upper)&.dig(:vdot) || 1.0
    else
      a = (upper[:vdot] - lower[:vdot]).to_f / (upper[:full_marathon_time] - lower[:full_marathon_time])
      b = upper[:vdot] - a * upper[:full_marathon_time]
      self.target_vdot = (a * target_marathon_time + b).round(2)
    end
  end

  # カテゴリ別トレーニングペース（秒/km）を線形補間で返す
  # category: :easy / :marathon / :threshold / :cv / :interval / :repetition
  def target_pace(category)
    pace_key = :"#{category}_pace"
    lower = VdotTable.find_lower(target_marathon_time)
    upper = VdotTable.find_upper(target_marathon_time)

    return 0 if lower.nil? || upper.nil?

    upper_pace = upper[pace_key]
    lower_pace = lower[pace_key]
    a = (upper_pace - lower_pace).to_f / (upper[:vdot] - lower[:vdot])
    b = upper_pace - a * upper[:vdot]
    (a * target_vdot + b).round(2)
  end

  private

    def update_target_marathon_time
      self.target_marathon_time = (@target_marathon_hours.to_i * 3600) +
                                  (@target_marathon_minutes.to_i * 60) +
                                  @target_marathon_seconds.to_i
    end

    def revised_at_must_be_unique_per_user
      return if revised_at.blank? || user_id.blank?

      conflict = TargetTime.where(user_id: user_id, revised_at: revised_at)
                           .where.not(id: id)
                           .exists?
      errors.add(:revised_at, :taken) if conflict
    end
end
