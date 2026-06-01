class ActivitiesController < ApplicationController
  before_action :authenticate_user!

  def index
    @activities = current_user.activities.recent.page(params[:page]).per(20)
  end

  def sync
    result = StravaActivitySyncService.new(current_user).call
    if result.success?
      redirect_to activities_path, notice: "#{result.imported_count}件のアクティビティを取得しました"
    else
      redirect_to activities_path, alert: "同期に失敗しました: #{result.error_message}"
    end
  end
end
