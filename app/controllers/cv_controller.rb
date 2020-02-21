class CvController < BaseController
  skip_authorize_resource
  skip_before_action :authenticate_user!
  before_action :load_coupon, only: %i[display consume]

  layout 'view_coupon_application'

  def display
  end

  def consume
    @coupon_sms_review.consume_coupon if @coupon_sms_review.present?
    redirect_to display_cv_index_path(@coupon_sms_review.slug)
  end

  private

  def load_coupon
    @coupon_sms_review = CouponSmsReview.includes(:coupon).find_by slug: params[:slug]
  end
end
