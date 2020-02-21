class Setting::StaffsController < BaseController
  def index
    @staffs = Staff.accessible_by(current_ability).order('id ASC').page(params[:page]).per(DEFAULT_PER_PAGE)
  end

  def create
    @staff.user = current_user
    if @staff.save!
      flash[:success] = '作成に成功しました'
    else
      flash[:danger] = '作成に失敗しました'
    end
    redirect_to setting_staffs_path
  end

  def update
    if @staff.save
      flash[:success] = '更新成功しました'
    else
      flash[:danger] = '更新に失敗しました'
    end
    redirect_to setting_staffs_path
  end
end
