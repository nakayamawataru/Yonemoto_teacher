include ApplicationHelper

class BusinessReviewsController < ApplicationController
  layout 'review'

  before_action :business, only: [:show, :platforms, :platforms_google, :questions, :answer, :template_review, :feedback, :send_feedback]

  def show
  end

  def platforms
  end

  def platforms_google
  end

  def questions
    unless @business.show_qa
      redirect_to review_url_with_type(@business, params[:business_type])
    end
  end

  def answer
    qa_type =
      if params[:question_1] == 'yes' && params[:question_2] == 'yes'
        'A1'
      elsif params[:question_1] == 'yes' && params[:question_2] == 'no'
        'A2'
      elsif params[:question_1] == 'no' && params[:question_2] == 'yes'
        'A3'
      elsif params[:question_1] == 'no' && params[:question_2] == 'no'
        'A4'
      else
        ''
      end

    redirect_to template_review_r_path(id: @business.bid, business_type: params[:business_type], qa_type: qa_type)
  end

  def template_review
    @content = QaReview.find_by(business_id: @business.try(:id), qa_type: params[:qa_type]).try(:content).to_s
    @business_type =  params[:business_type]
  end

  def feedback
  end

  def send_feedback
    if @business&.owner.present?
      MessageMailer.feedback(@business.id, params[:feedback]).deliver_later
    end

    redirect_to thank_you_r_path(id: @business.bid)
  end

  def thank_you
    @business = Business.find_by(bid: params[:id])
  end

  private

  def business
    @business = Business.find_by(bid: params[:id])
    unless @business
      redirect_to thank_you_r_path
    end
  end
end
