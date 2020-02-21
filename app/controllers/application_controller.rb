class ApplicationController < ActionController::Base
  before_action :basic_authenticate
  before_action :validate_payment!

  DEFAULT_PER_PAGE = 20

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.json { head :forbidden, content_type: 'text/html' }
      format.html { redirect_to main_app.root_url, notice: exception.message }
      format.js   { head :forbidden, content_type: 'text/html' }
    end
  end

  def authorize_manager
    return false unless current_user
    session[:manager_id].present? || current_user.admin? || current_user.is_agent?
  end

  private

  def basic_authenticate
    return unless Rails.env.staging?
    authenticate_or_request_with_http_basic('Administration') do |username, password|
      username == ENV['BASIC_AUTH_USERNAME'] && password == ENV['BASIC_AUTH_PASSWORD']
    end
  end

  def validate_payment!
    return unless current_user
    redirect_to payment_path if !current_user.payment? && ['sessions', 'payments'].exclude?(controller_name)
  end
end
