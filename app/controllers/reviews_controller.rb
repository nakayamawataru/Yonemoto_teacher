class ReviewsController < BaseController
  include CookieUtil

  before_action :check_ability!, except: %i[index]
  before_action :load_data, only: %i[index export_csv reply destroy_reply]

  def index
    if @business.present?
      @reviews = @business.reviews.order(create_time: :desc).page(params[:page]).per(DEFAULT_PER_PAGE)
      @positive_reviews =
        @business.reviews.where(positive: true).order(create_time: :desc).page(params[:page_positive])
                 .per(DEFAULT_PER_PAGE)
      @negative_reviews =
        @business.reviews.where(negative: true).order(create_time: :desc).page(params[:page_negative])
                 .per(DEFAULT_PER_PAGE)
    end
    respond_to do |format|
      format.html do
        set_notification_cookie
      end
      format.js
    end
  end

  def show
    @review = Review.accessible_by(current_ability).find_by id: params[:id]
    return redirect_to reviews_path if @review.blank?
  end

  def fetch
    business = Business.accessible_by(current_ability).find_by id: params[:id]
    return redirect_to reviews_path if business.blank?
    if business.fetch_reviews
      flash[:success] = 'データを取得成功しました'
    else
      flash[:danger] = business&.errors&.full_messages.first || 'データを取得失敗しました'
    end
    redirect_to reviews_path(business_id: business)
  end

  def export_csv
    reviews = @business.reviews
    text_type_comment = ''
    word_type = ''
    if params[:type_comment] == 'positive'
      reviews = reviews.where(positive: true)
      text_type_comment = 'positive_'
      word_type = 'positive_keywords'
    elsif params[:type_comment] == 'negative'
      reviews = reviews.where(negative: true)
      text_type_comment = 'negative_'
      word_type = 'negative_keywords'
    end

    file_name = "business_#{@business.id}_review_#{text_type_comment}#{Time.zone.now.strftime('%Y%m%d')}.csv"
    respond_to do |format|
      format.csv { send_data reviews.to_csv(word_type).encode(Encoding::SJIS, 'utf-8', undef: :replace), filename: file_name, type: 'text/csv; charset=shift_jis' }
    end
  end

  def reply
    status = false
    review = @business&.reviews&.find_by(id: params[:id])

    if @business && review
      client = GoogleBusinessApi.new(google_account_id: @business.google_account_id, google_account_refresh_token: @business.google_account_refresh_token)
      content_reply = review_reply_params[:content]
      response = client.reply_review(@business.location_id, review.review_id, content_reply)
      status = review.update(reply_content: response['comment'], reply_update_time: response['updateTime']) unless response['error'].present?
    end

    render json: {
      status: status,
      review: review
    }
  end

  def destroy_reply
    status = false
    review = @business&.reviews&.find_by(id: params[:id])

    if @business
      client = GoogleBusinessApi.new(google_account_id: @business.google_account_id, google_account_refresh_token: @business.google_account_refresh_token)
      response = client.delete_reply_review(@business.location_id, review.review_id)
      status = review.update(reply_content: nil, reply_update_time: nil) unless response['error'].present?
    end

    render json: {
      status: status,
      review: review
    }
  end

  private

  def check_ability!
    authorize! :index, self
  end

  def load_data
    @businesses = Business.accessible_by(current_ability)
    if current_user.owner?
      @business = current_user.owner_business
    else
      @business = @businesses.find_by id: (params[:business_id] || params[:reply_review].try(:[], :business_id))
    end
  end

  def review_reply_params
    params.require(:reply_review).permit(:business_id, :content)
  end
end
