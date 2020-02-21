class Setting::WidgetsController < BaseController
  skip_authorize_resource
  before_action :check_ability!
  skip_before_action :build_instance, :set_params

  def index
    gon.push({ base_url: ENV['DOMAIN'] })
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

  def check_ability!
    authorize! :index, self
  end

  def model_params
    params.permit [:sms_in_day, :review_in_day, holiday: []]
  end
end
