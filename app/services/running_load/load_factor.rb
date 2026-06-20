module RunningLoad
  # ペース(秒/km)と目標タイムから負荷係数・カテゴリを算出する純粋なロジック。
  # Calculator(activity単位)とActivitySplit(split単位)の双方から利用される。
  module LoadFactor
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

    module_function

    # pace(秒/km) と duration(秒) から load_score 相当の値を返す
    def score(pace:, duration:, target_time:)
      factor = factor_for_pace(pace, target_time)
      return nil if factor.nil?

      factor * duration / STANDARD_LOAD / 60 * 100
    end

    def factor_for_pace(pace, target_time)
      return nil if pace.blank? || target_time.nil?

      target_paces = target_paces_for(target_time)

      if pace >= target_paces[:easy]
        LOAD_HASH[:easy]
      elsif pace <= target_paces[:repetition]
        LOAD_HASH[:repetition]
      else
        target_paces.each_cons(2) do |(current_cat, current_pace), (next_cat, next_pace)|
          if current_pace >= pace && pace > next_pace
            return interpolate(
              pace, current_pace, next_pace,
              LOAD_HASH[current_cat], LOAD_HASH[next_cat]
            )
          end
        end
        nil
      end
    end

    def category_for_pace(pace, target_time)
      return nil if pace.blank? || target_time.nil?

      target_paces = target_paces_for(target_time)

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

    def target_paces_for(target_time)
      CATEGORIES.index_with { |cat| target_time.target_pace(cat) }
    end

    def interpolate(pace, current_pace, next_pace, current_load, next_load)
      slope = (next_load - current_load) / (next_pace - current_pace).to_f
      current_load + slope * (pace - current_pace)
    end
  end
end
