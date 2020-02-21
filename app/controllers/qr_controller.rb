class QrController < BaseController
  skip_authorize_resource
  skip_before_action :authenticate_user!
  skip_before_action :set_instance
  before_action :load_business, only: %i[simple anonymous normal normal_process sms sms_process]

  layout 'qr_application'

  def simple
    gon.push({
      review_url: @business.review_url
    })
  end

  def anonymous
    gon.push({
      review_url: @business.review_url
    })
  end

  def normal
  end

  def normal_process
    # TODO: need some logic
    redirect_to simple_qr_index_path(business_id: @business.id)
  end

  def sms
  end

  def sms_process
    # TODO: need some logic
    redirect_to simple_qr_index_path(business_id: @business.id)
  end

  private

  def load_business
    @business = Business.find_by(id: params[:business_id])
    render_404 and return unless @business.present?
    @staffs = Staff.where(id: @business.messages.pluck(:staff_id).uniq)
  end
end
