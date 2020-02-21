class Setting::ReplyReviewsController < BaseController
  skip_before_action :build_instance, :set_params
  before_action :load_business, only: %i[index create]
  before_action :is_operator!
  before_action :reply_review_params, only: :create

  def index
    @rv_less_2_stars = @business&.reply_reviews&.less_two_stars&.first
    @rv_greater_3_stars = @business&.reply_reviews&.greater_three_stars&.first
    @rv_less_2_stars_nc = @business&.reply_reviews&.less_two_stars_no_comment&.first
    @rv_greater_3_stars_nc = @business&.reply_reviews&.greater_three_stars_no_comment&.first
  end

  def create
    status = false
    if @business.present?
      reply_review = @business.reply_reviews.find_or_initialize_by(id: params[:reply_review_id])
      status = reply_review.update(reply_review_params)
    end

    render json: {
      status: status,
      type_review: ReplyReview.type_review_to_text(params[:type_review])
    }
  end

  private

  def load_business
    @business = Business.accessible_by(current_ability).find_by(id: params[:business_id])
  end

  def reply_review_params
    params.permit(:content, :type_review, :auto_reply)
  end
end
