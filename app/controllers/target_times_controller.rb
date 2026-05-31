class TargetTimesController < ApplicationController
  before_action :authenticate_user!

  def index
    @target_times = current_user.target_times.order(revised_at: :desc)
  end

  def new
    @target_time = current_user.target_times.build(revised_at: Date.today)
  end

  def create
    @target_time = current_user.target_times.build(target_time_params)
    @target_time.calc_target_vdot

    if @target_time.save
      redirect_to target_times_path, notice: "目標タイムを保存しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

    def target_time_params
      params.require(:target_time).permit(
        :target_marathon_hours,
        :target_marathon_minutes,
        :target_marathon_seconds,
        :revised_at
      )
    end
end
