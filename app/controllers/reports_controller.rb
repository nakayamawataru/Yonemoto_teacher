class ReportsController < BaseController
  skip_authorize_resource
  before_action :check_ability!
  before_action :load_data, only: :index

  def index
    @first_queries_direct = 0
    @first_queries_indirect = 0
    @second_queries_direct = 0
    @second_queries_indirect = 0

    if @business && @first_month_from.present? &&  @first_month_to.present? && @second_month_from.present? && @second_month_to.present?
      first_ranges = ((@first_month_from + '-1').to_date..(@first_month_to + '-1').to_date).to_a.map{|m| m.strftime('%Y-%m')}.uniq
      second_ranges = ((@second_month_from + '-1').to_date..(@second_month_to + '-1').to_date).to_a.map{|m| m.strftime('%Y-%m')}.uniq
      first_queries_chain = @business.insights.queries_chain.where(month_in: first_ranges).sum(:value)
      second_queries_chain = @business.insights.queries_chain.where(month_in: second_ranges).sum(:value)
      @first_queries_direct = @business.insights.queries_direct.where(month_in: first_ranges).sum(:value)
      @first_queries_indirect = @business.insights.queries_indirect.where(month_in: first_ranges).sum(:value) - first_queries_chain
      @second_queries_direct = @business.insights.queries_direct.where(month_in: second_ranges).sum(:value)
      @second_queries_indirect = @business.insights.queries_indirect.where(month_in: second_ranges).sum(:value) - second_queries_chain
    end
  end

  private

  def check_ability!
    authorize! :index, self
  end

  def load_data
    @businesses = Business.accessible_by(current_ability)
    @business = @businesses.find_by(id: params[:business_id])
    @first_month_from = params[:first_month_from]
    @first_month_to = params[:first_month_to]
    @second_month_from = params[:second_month_from]
    @second_month_to = params[:second_month_to]
    @month_rank = params[:month_rank]
  end
end
