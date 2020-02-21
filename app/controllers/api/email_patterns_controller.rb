class Api::EmailPatternsController < ApplicationController
  def content_pattern
    content =  EmailPattern.find_by(id: params[:id]).try(:content).to_s

    render json: { content: content }
  end
end
