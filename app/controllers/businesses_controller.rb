class BusinessesController < BaseController
  include CookieUtil

  def index
    if current_user.owner?
      return redirect_to (current_user.gmb_restricted ? reviews_path : charts_path)
    end

    @search = Business.accessible_by(current_ability).ransack(params[:q])
    @businesses = @search.result(distinct: true)
                         .group('businesses.id')
                         .includes(:user)
                         .order('businesses.id DESC')
                         .page(params[:page]).per(DEFAULT_PER_PAGE)
    check_connecting_gmb()
    respond_to do |format|
      format.html do
        set_notification_cookie
      end
      format.js do
        render layout: false
      end
    end
  end

  def new
    if current_user.demo_user? && current_user.businesses.size >= User::DEMO_BUSINESS_MAX
      flash[:danger] = "デモ期間中の案件は#{User::DEMO_BUSINESS_MAX}案件までになります"
      return redirect_to businesses_path
    end

    @business.build_owner
  end

  def show
    redirect_to edit_business_path @business
  end

  def edit
    session[:business_id] = @business.id
    @locations = nil
    if session[:google_connected].present?
      @locations = @business.google_locations
    end
    @business.build_owner if @business.owner.blank?
    @base_address_exist =
      BaseLocation.exist_base_location? @business.base_address
    session.delete(:google_connected)
  end

  def create
    if current_user.demo_user?
      if current_user.businesses.size >= User::DEMO_BUSINESS_MAX
        flash[:danger] = "デモ期間中の案件は#{User::DEMO_BUSINESS_MAX}案件までになります"
        return render :new
      end

      if @business.keywords.size > User::DEMO_KEYWORD_MAX
        flash[:danger] = "デモ期間中のキーワードは#{User::DEMO_KEYWORD_MAX}キーワードまでになります"
        return render :new
      end
    end

    @business.owner.plan_id = 6 if @business.owner.present?
    if @business.save
      flash[:success] = '作成成功。GMB連携をお願い致します。'
      redirect_to edit_business_path(@business.id)
    else
      flash[:danger] = '作成に失敗しました'
      render :new
    end
  end

  def update
    if current_user.demo_user?
      if current_user.businesses.size > User::DEMO_BUSINESS_MAX
        flash[:danger] = "デモ期間中の案件は#{User::DEMO_BUSINESS_MAX}案件までになります"
        return render :edit
      end

      if @business.keywords.size > User::DEMO_KEYWORD_MAX
        flash[:danger] = "デモ期間中のキーワードは#{User::DEMO_KEYWORD_MAX}キーワードまでになります"
        return render :edit
      end
    end

    @business.owner.plan_id = 6 if @business.owner.present?
    @business.remove_logo_review_message! if params[:remove_logo_review_message] == "0"
    if @business.save
      flash[:success] = '更新成功しました'
      redirect_to edit_business_path(@business)
    else
      flash[:danger] = '更新に失敗しました'
      render :edit
    end
  end

  def destroy
    if @business.destroy
      flash[:success] = '削除しました'
    else
      flash[:danger] = '削除できませんでした'
    end
    redirect_to businesses_path
  end

  def connect_google_location
    @business.assign_attributes(gmb_connect_status: Business.gmb_connect_statuses[:connecting], last_connected_at: Time.zone.now)

    if @business.save
      @business.update_google_business(params[:location_id])
      flash[:success] = 'GMB連携完了'
    else
      flash[:danger] = 'GMB連携失敗'
    end

    redirect_to edit_business_path(@business)
  end

  def edit_memo
    date = params[:date].to_date
    if params[:next] == 'true'
      date = date.tomorrow
    elsif params[:previous] == 'true'
      date = date.yesterday
    end
    render '_memo_modal', locals: { business: @business, date: date }, layout: false
  end

  def update_memo
    @business.owner.plan_id = 6 if @business.owner.present?
    if @business.save
      flash[:success] = 'メモ記録成功しました'
    else
      flash[:danger] = 'メモ記録に失敗しました'
    end
    session[:memo_date] = params[:memo_date]

    redirect_back(fallback_location: charts_path)
  end

  private

  def set_params
    params = param_clean(model_params)
    return unless params

    instance.assign_attributes params
  end

  def param_clean(_params)
    _params && _params.delete_if do |k, v|
      if v.instance_of?(ActionController::Parameters)
        param_clean(v)
      end

      Business::ALLOW_EMPTY_ATTRIBUTES.include?(k.to_sym) ? false : v.empty?
    end
  end

  def check_connecting_gmb
    return if @businesses.blank?
    @businesses.connecting.where("last_connected_at <= ?", Time.zone.now - 5.minutes).update_all(gmb_connect_status: Business.gmb_connect_statuses[:api_errors])
  end
end
