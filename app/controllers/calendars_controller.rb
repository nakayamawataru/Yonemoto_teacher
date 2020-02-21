class CalendarsController < BaseController
  include CalendarUtil

  skip_authorize_resource
  before_action :check_ability!
  before_action :load_business, only: %i[index export_csv export_rank]

  def index
    @parse_month = Date.new(@month.split("/")[0].to_i, @month.split("/")[1].to_i)
    gon.push({
      events: @events,
      selected_month: @month
    })
  end

  def export_csv
    @filename = "calendar_of_business_#{@business.id}_export_date_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.csv"
    respond_to do |format|
      format.csv { send_data csv_data.encode(Encoding::SJIS, 'utf-8', undef: :replace), filename: @filename,
        type: 'text/csv; charset=shift_jis' }
    end
  end

  def export_rank
    meo_histories = MeoHistory.where(business: @business,
      date: @month.to_date.beginning_of_month..@month.to_date.end_of_month)
    file_name = "meo_histories_#{@month.to_date.strftime('%Y_%m')}.csv"

    respond_to do |format|
      format.csv { send_data meo_histories.to_csv.encode(Encoding::SJIS, 'utf-8', undef: :replace), filename: file_name,
        type: 'text/csv; charset=shift_jis' }
    end
  end

  def image_rank
    render layout: false
  end

  def update_rank
    meo_id = params[:meo_id]
    rank = (params[:rank].to_i > 20 || params[:rank].to_i <= 0) ? 21 : params[:rank].to_i
    @meo_history = MeoHistory.find_by(id: meo_id)
    if current_user.admin? && @meo_history && @meo_history.update(rank: rank)
      render json: { status: true, message: '順位更新成功しました', rank: rank }
    else
      render json: { status: false, message: '順位更新が失敗しました', rank: rank }
    end
  end

  private

  def check_ability!
    authorize! :index, self
  end

  def load_business
    @month = (params[:month].blank? ? Date.today : params[:month].to_date).strftime("%Y/%m")
    @within_rank = params[:within_rank].blank? ? 'all' : params[:within_rank]
    @businesses = Business.accessible_by(current_ability)
    @business = current_user.owner? ? current_user.owner_business : @businesses.find_by(id: params[:business_id])
    load_data
  end

  def load_data
    @events = load_events(nil, current_user)
    @days_within_rank_3 = load_events(3, current_user).map{|item| item[:start]}.uniq.size
    @price_by_month = MonthlyFee.find_by(business: @business, month_in: @month.to_date.strftime('%Y-%m')).try(:value).to_i
    @total_money = @price_by_month * load_events(3, current_user).map{|item| item[:start]}.uniq.size
  end
end
