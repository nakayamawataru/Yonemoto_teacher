class Api::SmsPatternsController < ApplicationController
  def content_pattern
    content =  SmsPattern.find_by(id: params[:id]).try(:content).to_s

    render json: { content: content }
  end
end
