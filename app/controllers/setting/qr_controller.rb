class Setting::QrController < BaseController
  include QrUtil

  skip_authorize_resource
  skip_before_action :build_instance, :set_params
  before_action :load_business, only: %i[index create]
  before_action :is_operator!

  def index
    @qr_types = QR_TYPES
  end

  def create
    if make_qr_image
      flash[:success] = '作成に成功しました'
    else
      flash[:danger] = '作成に失敗しました'
    end
    redirect_to setting_qr_index_path(business_id: @business, qr_type: params[:qr_type])
  end

  private

  def load_business
    @business = Business.accessible_by(current_ability).find_by(id: params[:business_id])
  end
end
