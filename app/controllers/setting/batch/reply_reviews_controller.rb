class Setting::Batch::ReplyReviewsController < BaseController
  skip_before_action :build_instance, :set_params
  before_action :load_businesses, only: %i[create]
  before_action :is_operator!
  before_action :reply_review_params, only: :create

  def index
  end

  def create
    status = false
    ActiveRecord::Base.transaction do
      @businesses&.each do |business|
        reply_reviews = business.reply_reviews.try(params[:type_review].to_sym)
        reply_review = reply_reviews&.first
        status = reply_review.present? ? reply_review.update(reply_review_params) : reply_reviews.create(reply_review_params)
      end
    end

    render json: {
      status: status,
      type_review: ReplyReview.type_review_to_text(params[:type_review])
    }
  end

  private

  def load_businesses
    @businesses = Business.accessible_by(current_ability).where(user_id: params[:user_ids])
  end

  def reply_review_params
    params.permit(:content, :type_review, :auto_reply)
  end
end
