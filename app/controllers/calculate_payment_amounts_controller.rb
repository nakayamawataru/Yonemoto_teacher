class CalculatePaymentAmountsController < ApplicationController
  include ChartUtil

  before_action :authenticate_user!
  before_action :load_data, only: :index

  def index
    authorize! :index, self

    @labels = get_date_labels
    @businesses = (params[:business_ids].present? ? @businesses.where(id: params[:business_ids]) : @businesses).uniq
    @businesses = Kaminari.paginate_array(@businesses).page(params[:page]).per(DEFAULT_PER_PAGE)
  end

  private

  def load_data
    params[:month] ||= Date.today.strftime("%Y/%m")
    @months = ((Date.today - 11.month)..Date.today).to_a.map{|month| [month.strftime('%Y/%m'), month.strftime('%Y年%m月')]}.uniq.reverse
    @businesses = Business.accessible_by(current_ability).active
    @businesses = @businesses.not_managed_by_agent if current_user.admin?
  end
end
