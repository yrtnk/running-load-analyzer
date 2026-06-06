class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    aggregator = RunningLoad::WeeklyAggregator.new(current_user)
    @load_data = aggregator.call
    @recent_activities = current_user.activities.runs.recent.limit(10)
  end
end
