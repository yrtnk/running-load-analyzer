class ActivitiesController < ApplicationController
  before_action :authenticate_user!

  def index
    @activities = current_user.activities.recent.page(params[:page]).per(20)
  end

  def sync
    result = StravaActivitySyncService.new(current_user).call
    if result.success?
      redirect_to activities_path, notice: "#{result.imported_count}件のアクティビティを取得しました"
    elsif result.requires_reauth?
      flash[:reauth_required] = true
      redirect_to activities_path, alert: "Stravaの連携権限が不足しています。再度Stravaと連携してください。"
    else
      redirect_to activities_path, alert: "同期に失敗しました: #{result.error_message}"
    end
  end
end
