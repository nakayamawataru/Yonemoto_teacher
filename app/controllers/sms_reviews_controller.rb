class SmsReviewsController < ApplicationController
  before_action :authenticate_user!

  def create
    sms_review = SmsReview.create(sms_review_params)

    render json: sms_review
  end

  def show
    sms_review = SmsReview.find_by(id: params[:id])

    render json: sms_review
  end

  def update
    sms_review = SmsReview.find_by(id: params[:sms_review][:sms_review_id])
    sms_review.update!(sms_review_params) if sms_review

    render json: sms_review
  end

  private

  def sms_review_params
    params.require(:sms_review).permit(:username, :phone_number, :business_id)
  end
end
