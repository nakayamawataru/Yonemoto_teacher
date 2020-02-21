class Setting::QaReviewsController < BaseController
  skip_authorize_resource
  before_action :check_ability!
  skip_before_action :build_instance, :set_params
  before_action :load_business, only: %i[index create]

  def index
  end

  def create
    @business.update(show_qa: params[:show_qa])
    save_qa_review(QaReview::QUESTION_1, params[:question_1])
    save_qa_review(QaReview::QUESTION_2, params[:question_2])
    save_qa_review(QaReview::ANSWER_1, params[:answer_1])
    save_qa_review(QaReview::ANSWER_2, params[:answer_2])
    save_qa_review(QaReview::ANSWER_3, params[:answer_3])
    save_qa_review(QaReview::ANSWER_4, params[:answer_4])

    flash[:success] = '作成に成功しました'
    redirect_to setting_qa_reviews_path(business_id: @business.id)
  end

  private

  def check_ability!
    authorize! :index, self
  end

  def load_business
    @business = Business.accessible_by(current_ability).find_by(id: params[:business_id])
  end

  def save_qa_review(qa_type, value)
    @business.qa_reviews.find_or_initialize_by(qa_type: qa_type).update(content: value)
  end
end
