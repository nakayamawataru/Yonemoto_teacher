class Setting::GoalsController < BaseController
  skip_authorize_resource
  skip_before_action :build_instance, :set_params
  before_action :is_operator!

  def index
  end

  def create
    setting_goal = SettingGoal.find_or_initialize_by(user: current_user)
    setting_goal.assign_attributes model_params
    if setting_goal.save
      flash[:success] = '作成に成功しました'
    else
      flash[:danger] = '作成に失敗しました'
    end
    redirect_to setting_goals_path
  end

  private

  def model_params
    params.permit [:sms_in_day, :review_in_day, holiday: []]
  end
end
