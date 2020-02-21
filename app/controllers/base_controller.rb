class BaseController < ActionController::Base
  DEFAULT_PER_PAGE = 20

  before_action :basic_authenticate
  before_action :authenticate_user!
  before_action :validate_payment!
  before_action :build_instance, only: %i[new create]
  before_action :set_instance, only: %i[update destroy show edit preview sms connect_google_location edit_memo update_memo]
  before_action :set_params, only: %i[create update update_memo]

  authorize_resource

  layout "application"

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.json { head :forbidden, content_type: 'text/html' }
      format.html { redirect_to main_app.root_url, notice: exception.message }
      format.js   { head :forbidden, content_type: 'text/html' }
    end
  end

  def new
  end

  def edit
  end

  protected

  def render_404
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/404", :layout => false, :status => :not_found }
      format.xml  { head :not_found }
      format.any  { head :not_found }
    end
  end

  def check_restricted_review
    if current_user.restricted
      respond_to do |format|
        format.json { head :forbidden, content_type: 'text/html' }
        format.html { redirect_to main_app.root_url, notice: '詳しくは営業担当にお問い合わせください。' }
        format.js   { head :forbidden, content_type: 'text/html' }
      end
    end
  end

  def is_operator!
    # redirect_to root_path unless current_user.admin? || current_user.is_agent?
  end

  def model
    controller_name.classify.safe_constantize
  end

  def model_name
    controller_name.singularize
  end

  def model_name_symbol
    model_name.intern
  end

  def build_instance
    _instance = model.new
    instance_variable_set "@#{model_name}", _instance
  end

  def set_instance
    _instance = model.find_by id: params[:id]
    return redirect_to root_url unless _instance.present?
    instance_variable_set "@#{model_name}", _instance
  end

  def instance
    instance_variable_get "@#{model_name}"
  end

  def set_params
    instance.assign_attributes model_params
  end

  def model_params
    return unless params[model_name_symbol]
    params.require(model_name_symbol)
      .permit model::DEFAULT_UPDATABLE_ATTRIBUTES
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
