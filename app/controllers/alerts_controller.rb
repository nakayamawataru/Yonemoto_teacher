class AlertsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_business, only: :index

  layout "application"

  def index
    authorize! :index, self
    respond_to do |format|
      format.html do
        load_out_rank
        load_top_rank
      end
      format.js do
        load_out_rank if params[:type] == 'out_rank' || params[:type].nil?
        load_top_rank if params[:type] == 'top_rank' || params[:type].nil?
      end
    end
  end

  private

  def load_business
    @businesses = current_user.admin? ?
                  (Business.not_managed_by_agent_and_agent_meo_check.not_managed_by_demo_entry_users + Business.managed_by_agent_meo_check_with_plan([Plan::KEYWORD_MEO, Plan::MEO_BASIC])) :
                  Business.accessible_by(current_ability)
  end

  def load_out_rank
    @date = (params[:date] || Time.zone.today).to_date
    top_rank_keyword_ids = MeoHistory.where(date: @date - 1.day, business: @businesses, rank: [1, 2, 3]).pluck(:keyword_id)
    in_rank_keyword_ids = MeoHistory.where(date: @date - 1.day, business: @businesses, rank: 1..20).pluck(:keyword_id)

    meo_histories = MeoHistory.where(date: @date, business: @businesses)
    @out_rank_list = meo_histories.where(rank: 4..20, keyword_id: top_rank_keyword_ids)
      .or(meo_histories.where(keyword_id: in_rank_keyword_ids).where.not(rank: 1..20))
      .page(params[:page_out_rank]).per(20)
  end

  def load_top_rank
    @date_top_rank = (params[:date_top_rank] || Time.zone.today).to_date
    keyword_ids = MeoHistory.where(date: @date_top_rank - 1.day, business: @businesses, rank: [1, 2, 3]).pluck(:keyword_id)

    @top_rank_list = MeoHistory.where(date: @date_top_rank, business: @businesses, rank: [1, 2, 3])
      .where.not(keyword_id: keyword_ids).page(params[:page_top_rank]).per(20)
  end
end
