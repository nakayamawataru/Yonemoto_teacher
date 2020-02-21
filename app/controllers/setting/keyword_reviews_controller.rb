class Setting::KeywordReviewsController < BaseController
  before_action :authourize_white_list, only: :index

  def index
    @word_type = params[:word_type].present? ? params[:word_type] : 'positive'
    @keyword_reviews =
      if current_user.admin?
        KeywordReview.accessible_by(current_ability).try(@word_type.to_sym).where(user: nil).page(params[:page]).per(DEFAULT_PER_PAGE)
      else
        KeywordReview.accessible_by(current_ability).try(@word_type.to_sym).where(user: current_user).page(params[:page]).per(DEFAULT_PER_PAGE)
      end
  end

  def create
    if @keyword_review.save
      flash[:success] = '作成に成功しました'
    else
      flash[:danger] = '作成に失敗しました'
    end
    redirect_to setting_keyword_reviews_path(word_type: model_params[:word_type])
  end

  def update
    if @keyword_review.save
      flash[:success] = '更新成功しました'
    else
      flash[:danger] = '更新に失敗しました'
    end
    redirect_to setting_keyword_reviews_path(word_type: model_params[:word_type])
  end

  def destroy
    word_type = @keyword_review.word_type
    if @keyword_review.destroy
      flash[:success] = '削除しました'
    else
      flash[:danger] = '削除できませんでした'
    end
    redirect_to setting_keyword_reviews_path(word_type: word_type)
  end

  private

  def authourize_white_list
    if !current_user.admin? && params[:word_type] != 'whitelist'
      redirect_to root_path
    end
  end
end
