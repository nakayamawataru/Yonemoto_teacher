class Setting::SmsController < BaseController
  skip_authorize_resource
  skip_before_action :build_instance, :set_params
  before_action :load_business, only: %i[index create]
  before_action :is_operator!

  def index
    unless params[:content_blank].blank?
      flash[:alert] = 'SMSテキストの設定をお願いします'
    end
    @setting_sms = SettingSms.find_or_initialize_by(business: @business)
    @setting_sms.sms_patterns.build if @setting_sms.sms_patterns.blank?
  end

  def create
    @setting_sms = SettingSms.find_or_initialize_by(business: @business)
    @setting_sms.assign_attributes model_params
    if @setting_sms.review_url_enabled && @setting_sms.business.review_url.blank?
      flash[:danger] = 'GMB連携に失敗しております。GMB編集ページより連携をお願いします。'
      return redirect_to setting_sms_path(business_id: @business)
    end
    # if setting_sms.review_url_enabled && !setting_sms.content.include?("writereview?placeid")
    #   setting_sms.content = setting_sms.content + "\r\n" + setting_sms.business.review_url
    # end
    set_pattern_name(@setting_sms)
    if @setting_sms.save
      flash[:success] = '作成に成功しました'
      redirect_to setting_sms_path(business_id: @business)
    else
      flash[:danger] = '作成に失敗しました'
      render :index
    end
  end

  private

  def model_params
    params.require(:setting_sms).permit :review_url_enabled,
      sms_patterns_attributes: [:id, :content, :_destroy]
  end

  def load_business
    @business = Business.accessible_by(current_ability).find_by(id: params[:business_id])
  end

  def set_pattern_name(setting_sms)
    patterns = setting_sms.sms_patterns.select{|pattern| !pattern.marked_for_destruction?}
    patterns.each_with_index do |pattern, index|
      pattern.assign_attributes(name: 'パターン' + (index + 1).to_s)
    end
  end
end
