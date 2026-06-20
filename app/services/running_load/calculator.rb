module RunningLoad
  class Calculator
    def initialize(activity, target_time)
      @activity = activity
      @target_time = target_time
    end

    def call
      return nil if @target_time.nil?
      return nil if @activity.average_pace.blank? || @activity.moving_time.blank?

      score = LoadFactor.score(
        pace: @activity.average_pace,
        duration: @activity.moving_time,
        target_time: @target_time
      )
      return nil if score.nil?

      score.round(2)
    end

    def category
      return nil if @target_time.nil?
      return nil if @activity.average_pace.blank?

      LoadFactor.category_for_pace(@activity.average_pace, @target_time)&.to_s
    end
  end
end
