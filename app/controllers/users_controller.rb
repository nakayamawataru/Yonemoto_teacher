class UsersController < BaseController
  before_action :change_restriction_user, if: -> { current_user.is_agent? }, only: %i[create update]

  def index
    @search = User.accessible_by(current_ability).ransack(params[:q])
    result = @search.result(distinct: true)
    if params[:filter_payment].present?
      result = result.where.not(payjp_customer_id: '', card: '') if params[:filter_payment] == 'payment'
      result = result.where.not(expire_at: '') if params[:filter_payment] == 'expire'
    end

    @users = result.order('id DESC').page(params[:page]).per(DEFAULT_PER_PAGE)
    respond_to do |format|
      format.html
      format.js { render layout: false }
    end
  end

  def show
    redirect_to edit_user_path @user
  end

  def create
    @user.plan_id = 6 unless current_user.admin?
    if @user.save
      flash[:success] = '作成に成功しました'
      redirect_to users_path
    else
      flash[:danger] = '作成に失敗しました'
      render :new
    end
  end

  def update
    @user.plan_id = 6 unless current_user.admin?
    @user.remove_logo! if params[:remove_logo] == "0"
    @user.remove_header_logo! if params[:remove_header_logo] == "0"
    if @user.save
      flash[:success] = '更新成功しました'
      redirect_to users_path
    else
      flash[:danger] = '更新に失敗しました'
      render :edit
    end
  end

  def update_payment_discount
    @user = User.accessible_by(current_ability).find_by(id: params[:user_id])
    if can? :update_payment_discount, @user
      @user.update(payment_discount: params[:payment_discount])
      flash[:success] = '更新成功しました'
    else
      flash[:danger] = '更新に失敗しました'
    end

    redirect_to payments_path(user_id: @user.try(:id))
  end

  def destroy
    if @user.destroy
      flash[:success] = '削除しました'
    else
      flash[:danger] = '削除できませんでした'
    end
    redirect_to users_path
  end

  def remove_card
    return unless current_user.admin?

    user = User.find_by(id: params[:user_id])
    if user
      user.update(payjp_card_token: nil)
      user.update(payjp_customer_id: nil)
      user.update(card: nil)

      flash[:success] = 'クレジットカード削除成功'
    else
      flash[:danger] = '不正なユーザーです'
    end

    redirect_back(fallback_location: root_path)
  end

  private

  def set_params
    params = model_params[:password].empty? ? model_params.except('password') : model_params
    params = params.except(:expire_at) if @user == current_user || current_user.agent_meo_check?
    params = params.except(:restricted, :coupon_restricted, :max_sms_in_day) unless current_user.admin?
    params = params.except(:setting_calendar, :setting_memo) unless current_user.admin?
    instance.assign_attributes params
  end

  def change_restriction_user
    if @user.is_user?
      @user.assign_attributes(restricted: current_user.restricted, coupon_restricted: current_user.coupon_restricted)
    else
      @user.assign_attributes(restricted: current_user.restricted, coupon_restricted: current_user.coupon_restricted, gmb_restricted: current_user.gmb_restricted)
    end
  end
end
