class WidgetsController < ApplicationController
  protect_from_forgery except: [:show, :widget]
  before_action :set_cors_headers

  def show
    @business = Business.find_by id: params[:business_id]
    if params[:restricted] == "true"
      @reviews =
        @business ? @reviews = @business.reviews.order(create_time: :desc).where("star_rating > ?", 2).page(params[:page]).per(10) : []
    else
      @reviews =
        @business ? @reviews = @business.reviews.order(create_time: :desc).page(params[:page]).per(10) : []
    end

    render layout: false
  end

  def widget
    @base_url = ENV['DOMAIN']
  end

  private

  def set_cors_headers
    response.set_header 'Access-Control-Allow-Origin', origin
    response.set_header 'X-Frame-Options', 'ALLOWALL'
  end

  def origin
    request.headers["Origin"] || "*"
  end
end

