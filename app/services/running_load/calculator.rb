module RunningLoad
  class Calculator
    CATEGORIES = %i[easy marathon threshold cv interval repetition].freeze
    LOAD_HASH = {
      easy: 0.2,
      marathon: 0.4,
      threshold: 0.8,
      cv: 1.0,
      interval: 1.2,
      repetition: 1.5
    }.freeze
    # thresholdペースを60分継続したときを基準値(=100)とする
    STANDARD_LOAD = 60 * LOAD_HASH[:threshold]

    def initialize(activity, target_time)
      @activity = activity
      @target_time = target_time
    end

    def call
      return nil if @target_time.nil?
      return nil if @activity.average_pace.blank? || @activity.moving_time.blank?

      factor = load_factor_for_pace
      return nil if factor.nil?

      (factor * @activity.moving_time / STANDARD_LOAD / 60 * 100).round(2)
    end

    def category
      return nil if @target_time.nil?
      return nil if @activity.average_pace.blank?

      load_category_for_pace&.to_s
    end

    private

    def load_factor_for_pace
      pace = @activity.average_pace
      target_paces = CATEGORIES.map { |cat| [ cat, @target_time.target_pace(cat) ] }.to_h

      if pace >= target_paces[:easy]
        LOAD_HASH[:easy]
      elsif pace <= target_paces[:repetition]
        LOAD_HASH[:repetition]
      else
        target_paces.each_cons(2) do |(current_cat, current_pace), (next_cat, next_pace)|
          if current_pace >= pace && pace > next_pace
            return interpolate_load_factor(
              pace, current_pace, next_pace,
              LOAD_HASH[current_cat], LOAD_HASH[next_cat]
            )
          end
        end
        nil
      end
    end

    def load_category_for_pace
      pace = @activity.average_pace
      target_paces = CATEGORIES.map { |cat| [ cat, @target_time.target_pace(cat) ] }.to_h

      if pace >= target_paces[:easy]
        :easy
      elsif pace <= target_paces[:repetition]
        :repetition
      else
        target_paces.each_cons(2) do |(current_cat, current_pace), (next_cat, next_pace)|
          if current_pace >= pace && pace > next_pace
            nearest = (pace - next_pace).abs <= (pace - current_pace).abs ? next_cat : current_cat
            return nearest
          end
        end
        nil
      end
    end

    def interpolate_load_factor(pace, current_pace, next_pace, current_load, next_load)
      slope = (next_load - current_load) / (next_pace - current_pace).to_f
      current_load + slope * (pace - current_pace)
    end
  end
end
