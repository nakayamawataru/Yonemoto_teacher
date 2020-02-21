class CouponsController < BaseController
  before_action :check_ability!, except: %i[index]
  before_action :load_data, only: %i[index new]

  def index
    @coupons = Coupon.where(business: @business).page(params[:page]).per(DEFAULT_PER_PAGE)
    respond_to do |format|
      format.html
      format.js { render layout: false }
    end
  end

  def create
    if @coupon.save
      flash[:success] = '作成に成功しました'
      redirect_to coupons_path(business_id: model_params[:business_id])
    else
      flash[:danger] = '作成に失敗しました'
      redirect_to action: :new, business_id: model_params[:business_id], error: @coupon.errors.messages.present?
    end
  end

  def update
    if @coupon.save
      flash[:success] = '更新成功しました'
      redirect_to coupon_path(@coupon)
    else
      flash[:danger] = '更新に失敗しました'
      redirect_to action: :edit, business_id: model_params[:business_id], error: @coupon.errors.messages.present?
    end
  end

  def edit
    @business = @coupon.business
  end

  def show
    @tab = params[:tab].present? ? params[:tab] : 'info'
    gon.push({
      coupon_id: @coupon.id
    })
    @business = @coupon.business
    @sms_reviews = @business.sms_reviews.order('created_at DESC').page(params[:page]).per(DEFAULT_PER_PAGE)
    respond_to do |format|
      format.html
      format.js { render layout: false }
    end
  end

  def preview
    preview_slug = @coupon.save_preview
    return redirect_to display_cv_index_path(preview_slug) if preview_slug.present?
    redirect_to coupon_path(@coupon)
  end

  def sms
    @data_precence = params[:sms_review_ids].present?
    if @data_precence
      @failed_phone_nums = @coupon.send_sms params
      flash[:success] = 'SMSを送信成功しました' unless @failed_phone_nums.present?
    end
    respond_to(&:js)
  end

  def destroy
    business_id = @coupon.business_id
    if @coupon.destroy
      flash[:success] = '削除しました'
    else
      flash[:danger] = '削除できませんでした'
    end
    redirect_to coupons_path(business_id: business_id)
  end

  private

  def check_ability!
    authorize! :index, self
  end

  def load_data
    @businesses = Business.accessible_by(current_ability)
    @business = current_user.owner? ? current_user.owner_business : @businesses.find_by(id: params[:business_id])
  end
end
