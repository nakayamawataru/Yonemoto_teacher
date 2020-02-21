class ChartsController < BaseController
  include ChartUtil
  include CookieUtil

  skip_authorize_resource
  before_action :check_ability!, except: %i[iframe]
  before_action :load_data, only: %i[index]
  skip_before_action :authenticate_user!, only: %i[iframe]

  def index
    labels = get_date_labels
    datasets = load_data_meo(labels)
    @datasets_benchmark_business = []
    @benchmark_business = @business ? @business.benchmark_business : []
    @benchmark_business.each do |bb|
      @datasets_benchmark_business.push(load_data_meo_benchmark_business(bb, labels))
    end
    @data_charts = Kaminari.paginate_array(merge_data_charts(labels, datasets))
                           .page(params[:page]).per(10)
    @within_rank = params[:within_rank].present? ? params[:within_rank] : 'all'
    @date_ranking = params[:date_ranking].present? ? params[:date_ranking].to_date : Date.today
    @date_ranking =  session[:memo_date].to_date if session[:memo_date]
    session.delete(:memo_date)
    @data_rankings = MeoHistory.ranking_current_date(@date_ranking, @business)
    data_rank = datasets.select{|r| r[:data_type] == 'rank'}.map{|r| r[:data]}
    @rank_abs = data_rank.transpose.map{|arr| (arr.inject{|sum, e| (sum.to_i + e.to_i)}.to_f/data_rank.count).round(2)}
    @rank_abs = @rank_abs.map{|a| a > 0 ? a : nil}
    @index_rank = labels.find_index(@date_ranking.strftime('%Y/%m/%d'))
    @data_rank_abs = [{ label: "平均値", data: @rank_abs, borderColor: Keyword::COLORS.first }]
    @memos = @business&.memos&.accessible_by(current_ability)&.by_date(@date_ranking)

    gon.push({
      labels: labels,
      datasets: datasets,
      data_rank_abs: @data_rank_abs,
      datasets_benchmark_business: @datasets_benchmark_business.map{|data| data},
      within_rank: @within_rank == 'all' ? 21 : @within_rank,
      chart_category: false,
      default_date: @date_ranking.strftime('%d/%m/%Y')
    })
    respond_to do |format|
      format.html do
        set_notification_cookie
      end
      format.js
    end
  end

  def chart_category
    params[:month] = params[:month].blank? ? Date.today.strftime("%Y/%m") : params[:month]
    params[:gcid] = params[:gcid].blank? ? 'all' : params[:gcid]
    rank_histories = rank_category(params[:gcid]).map{ |r| r == 0 ? nil : r }
    data_rank_category = [{ label: "平均値", data: rank_histories, borderColor: Keyword::COLORS.first }]
    load_categories(get_date_labels)
    first_created_meo = MeoHistory.where.not(date: nil).order(:date).first.try(:date).try(:to_date) || Date.today
    @month_categories =
      (first_created_meo..Date.today).to_a.map do |month|
        [month.strftime('%Y年%m月'), month.strftime('%Y/%m')]
      end.uniq.reverse

    gon.push({
      labels: @labels,
      data_rank_category: data_rank_category,
      chart_category: true,
      within_rank: 21
    })
  end

  # chart_categoryと同じ
  def iframe
    params[:month] = params[:month].blank? ? Date.today.strftime("%Y/%m") : params[:month]
    params[:gcid] = params[:gcid].blank? ? 'all' : params[:gcid]
    rank_histories = rank_category(params[:gcid]).map{ |r| r == 0 ? nil : r }
    data_rank_category = [{ label: "平均値", data: rank_histories, borderColor: Keyword::COLORS.first }]
    load_categories(get_date_labels)
    first_created_meo = MeoHistory.where.not(date: nil).order(:date).first.try(:date).try(:to_date) || Date.today
    @month_categories =
      (first_created_meo..Date.today).to_a.map do |month|
        [month.strftime('%Y年%m月'), month.strftime('%Y/%m')]
      end.uniq.reverse

    gon.push({
      labels: @labels,
      data_rank_category: data_rank_category,
      chart_category: true,
      within_rank: 21
    })
    render :layout => 'non'
  end

  private

  def check_ability!
    authorize! :index, self
  end

  def load_data
    params[:month] = params[:month].blank? && params[:day_number].blank? ? Date.today.strftime("%Y/%m") : params[:month]
    @day_number = [30, 60, 120, 180]
    @businesses = Business.accessible_by(current_ability)
    @business = current_user.owner? ? current_user.owner_business : @businesses.find_by(id: params[:business_id])
  end

  def merge_data_charts(dates, data_meo)
    data_charts = []
    dates.each_with_index do |date, index|
      data_meo.each do |data|
        if data[:data][index]
          date = date.gsub("/", "-")
          keyword = data[:label]
          rank = rank_as_text(data[:data][index])

          data_charts.push({
            date: date,
            keyword: keyword,
            ranking: rank,
            base_location_japanese:
              MeoHistory.base_location_meo(@business, date, keyword, data[:data][index])})
        end
      end
    end

    data_charts
  end

  def rank_as_text(rank)
    rank < Settings.meo_history.out_of_range ? (rank.to_s + ' 位') : 'ランク外'
  end

  def load_categories(dates)
    gcids = CategoryRankHistory.where(date: dates).where('rank > ?', 0).order(:date).pluck(:gcid).uniq
    category_names = Category.pluck(:name, :gcid)
    @select_categories = [['全て', 'all']]
    gcids.each do |gcid|
      categorires = category_names.select{|c| c if c[1] == gcid}.map{|n| n[0]}
      @select_categories.push([categorires.join(' -- '), gcid]) if categorires.present?
    end
  end

  def rank_category(gcid)
    @labels = get_date_labels
    rank_category = get_rank(gcid, @labels)
    if rank_category.sum <= 0
      params[:gcid] = 'all'
      rank_category = get_rank(params[:gcid], @labels)

      if rank_category.sum <= 0
         params[:month] = Date.today.strftime("%Y/%m")
         @labels = get_date_labels
         rank_category = get_rank(params[:gcid], @labels)
      end
    end

    rank_category
  end

  def get_rank(gcid, dates)
    CategoryRankHistory.where(gcid: gcid, date: dates).order(:date).pluck(:rank)
  end
end
