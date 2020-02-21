class InsightsController < BaseController
  include InsightUtil
  include ApplicationHelper

  skip_authorize_resource
  before_action :check_ability!
  before_action :load_data, only: %i[index export export_csv]

  def index
  end

  def export
  end

  def export_csv
    begin
      date_export = params[:month].to_date
    rescue ArgumentError
      return
    end

    return if date_export > @date
    start_month = date_export.strftime("%Y-%m-%d")
    end_month = date_export.end_of_month.strftime("%Y-%m-%d")
    file_name = "インサイトデータ_#{start_month}_#{end_month}.csv"
    attributes = ['施設名', '検索合計', '直接検索', '間接検索', 'ブランド名', '表示合計',
      '検索画面', '地図画面', '行動合計', 'ウェブ', '経路', '電話', '投稿合計', 'オーナー投稿', '顧客投稿', '状態']

    businesses =
      if params[:business_ids].present?
        @businesses.where(id: params[:business_ids])
      else
        @businesses
      end

    content_csv =
      CSV.generate(headers: true) do |csv|
        csv << attributes
        businesses.each do |business|
          insights = business.insights_by_month(date_export).map{ |i| {data_type: Insight.data_types[i.data_type], value: i.value} }
          queries_direct = insights.find { |x| x[:data_type] == Insight.data_types[:queries_direct] }.try(:[], :value).to_i
          queries_indirect = insights.find { |x| x[:data_type] == Insight.data_types[:queries_indirect] }.try(:[], :value).to_i
          queries_chain = insights.find { |x| x[:data_type] == Insight.data_types[:queries_chain] }.try(:[], :value).to_i
          view_search = insights.find { |x| x[:data_type] == Insight.data_types[:view_search] }.try(:[], :value).to_i
          view_maps = insights.find { |x| x[:data_type] == Insight.data_types[:view_maps] }.try(:[], :value).to_i
          action_website = insights.find { |x| x[:data_type] == Insight.data_types[:action_website] }.try(:[], :value).to_i
          action_driving_direction = insights.find { |x| x[:data_type] == Insight.data_types[:action_driving_direction] }.try(:[], :value).to_i
          action_phone = insights.find { |x| x[:data_type] == Insight.data_types[:action_phone] }.try(:[], :value).to_i
          photo_views_merchant = insights.find { |x| x[:data_type] == Insight.data_types[:photo_views_merchant] }.try(:[], :value).to_i
          photo_views_customer = insights.find { |x| x[:data_type] == Insight.data_types[:photo_views_customer] }.try(:[], :value).to_i

          data = [business.name]
          data << (queries_direct + queries_indirect)
          data << queries_direct
          data << queries_indirect - queries_chain
          data << queries_chain
          data << (view_search + view_maps)
          data << view_search
          data << view_maps
          data << (action_website + action_driving_direction + action_phone)
          data << action_website
          data << action_driving_direction
          data << action_phone
          data << (photo_views_merchant + photo_views_customer)
          data << photo_views_merchant
          data << photo_views_customer
          data << convert_status(business.status)
          csv << data
        end
      end

    respond_to do |format|
      format.csv { send_data content_csv.encode(Encoding::SJIS, 'utf-8', undef: :replace),
        filename: file_name, type: 'text/csv; charset=shift_jis' }
    end
  end

  def fetch
    business = Business.accessible_by(current_ability).find_by id: params[:id]
    return redirect_to insights_path if business.blank?
    if business.clear_insights && business.fetch_insights
      flash[:success] = 'データを取得成功しました'
    else
      flash[:danger] = 'データを取得失敗しました'
    end
    redirect_to insights_path(business_id: business)
  end

  private

  def check_ability!
    authorize! :index, self
  end

  def load_data
    @date = day_insight_data.to_date
    params[:month] =
      params[:month].blank? ? @date.strftime("%Y/%m") : params[:month]
    @months =
      ((@date - 11.month)..@date).to_a.map do |month|
        [month.strftime('%Y/%m'), month.strftime('%Y年%m月')]
       end.uniq.reverse
    @businesses = Business.accessible_by(current_ability)
    @business = current_user.owner? ? current_user.owner_business : @businesses.find_by(id: params[:business_id])
    load_insight_data
  end
end
