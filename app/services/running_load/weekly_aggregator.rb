module RunningLoad
  class WeeklyAggregator
    WEEKS_TO_DISPLAY = 12
    STL_DAYS = 7
    LTL_DAYS = 30
    INJURY_RISK_THRESHOLD = 1.2

    def initialize(user)
      @user = user
    end

    def call
      {
        chart_data: weekly_chart_data,
        current_stl: current_stl,
        current_ltl: current_ltl,
        stl_ltl_diff: (current_stl - current_ltl).round(2),
        injury_risk: injury_risk?
      }
    end

    def current_stl
      @current_stl ||= daily_average_load(STL_DAYS)
    end

    def current_ltl
      @current_ltl ||= daily_average_load(LTL_DAYS)
    end

    def injury_risk?
      return false if current_ltl.zero?

      current_stl > current_ltl * INJURY_RISK_THRESHOLD
    end

    private

    def weekly_chart_data
      load_by_date = fetch_load_by_date
      weeks = build_weekly_data(load_by_date)
      {
        labels: weeks.map { |w| w[:label] },
        weekly_totals: weeks.map { |w| w[:total] },
        ltl_values: weeks.map { |w| w[:ltl] }
      }
    end

    def build_weekly_data(load_by_date)
      (0...WEEKS_TO_DISPLAY).map do |i|
        week_end = i.weeks.ago.end_of_week.to_date
        week_start = week_end - 6
        ltl_start = week_end - LTL_DAYS + 1

        {
          label: week_start.strftime("%m/%d"),
          total: sum_range(load_by_date, week_start, week_end).round(1),
          ltl: (sum_range(load_by_date, ltl_start, week_end) / LTL_DAYS * 7).round(1)
        }
      end.reverse
    end

    def fetch_load_by_date
      range_start = WEEKS_TO_DISPLAY.weeks.ago.beginning_of_week - LTL_DAYS.days
      @user.activities
           .runs
           .where(start_date: range_start.beginning_of_day..Time.current.end_of_day)
           .where.not(load_score: nil)
           .pluck(:start_date, :load_score)
           .each_with_object(Hash.new(0.0)) do |(date, score), hash|
             hash[date.to_date] += score
           end
    end

    def sum_range(load_by_date, from, to)
      (from..to).sum { |date| load_by_date[date] }
    end

    def daily_average_load(days)
      start_date = (days - 1).days.ago.to_date
      total = @user.activities
                   .runs
                   .where(start_date: start_date.beginning_of_day..Time.current.end_of_day)
                   .where.not(load_score: nil)
                   .sum(:load_score)
      (total / days.to_f).round(2)
    end
  end
end
