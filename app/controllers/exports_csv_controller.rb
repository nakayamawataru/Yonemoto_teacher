class ExportsCsvController < ApplicationController
  include ChartUtil
  include ApplicationHelper

  before_action :authenticate_user!
  before_action :check_ability!
  before_action :load_data, only: [:index, :export, :export_statictical_rank, :export_below_top_rank, :export_reviews]

  def index
    @export_info = [
      { path: export_exports_csv_index_path, title: '3位以内の集計結果ダウンロード(CSV)', businesses: @filtered_businesses },
      { path: export_statictical_rank_exports_csv_index_path, title: '3位以内の日数合計数ダウンロード', businesses: @filtered_businesses },
      { path: export_below_top_rank_exports_csv_index_path, title: '21位以内の順位ダウンロード', businesses: @filtered_businesses }
    ]
  end

  def export
    generate_csv(Business::DATA_RANK, true)
  end

  def export_statictical_rank
    generate_csv(Business::COUNT_RANK, true)
  end

  def export_below_top_rank
    generate_csv(Business::BELOW_TOP_RANK)
  end

  def export_reviews
    businesses = params[:business_ids].present? ? @businesses.where(id: params[:business_ids]) : @businesses
    reviews = Review.where(business: businesses)
    text_type_comment = ''
    word_type = ''
    if params[:type_comment] == 'positive'
      reviews = reviews.where(positive: true)
      text_type_comment = 'positive_'
      word_type = 'positive_keywords'
    elsif params[:type_comment] == 'negative'
      reviews = reviews.where(negative: true)
      text_type_comment = 'negative_'
      word_type = 'negative_keywords'
    end

    file_name = "business_review_#{text_type_comment}#{Time.zone.now.strftime('%Y%m%d')}.csv"
    respond_to do |format|
      format.csv { send_data reviews.to_csv(word_type).encode(Encoding::SJIS, 'utf-8', undef: :replace), filename: file_name, type: 'text/csv; charset=shift_jis' }
    end
  end

  private

  def check_ability!
    authorize! :index, self
  end

  def load_data
    params[:month] =
      params[:month].blank? && params[:day_number].blank? ?
        Date.today.strftime("%Y/%m") : params[:month]
    @months =
      ((Date.today - 11.month)..Date.today).to_a.map do |month|
        [month.strftime('%Y/%m'), month.strftime('%Y年%m月')]
       end.uniq.reverse
    @businesses = Business.accessible_by(current_ability).active
    if current_user.admin?
      @filtered_businesses = @businesses.not_managed_by_agent
    else
      @filtered_businesses = @businesses
    end
  end

  def generate_csv(type, business_filter=false)
    begin
      date_export = params[:month].to_date
    rescue ArgumentError
      return
    end

    labels = get_date_labels
    start_month = date_export.strftime("%Y-%m-%d")
    end_month = date_export.end_of_month.strftime("%Y-%m-%d")
    file_name = "MEO_#{start_month}_#{end_month}.csv"
    attributes =[]
    if type == Business::DATA_RANK
      attributes = (1..labels.count).to_a.unshift('施設名') + ['月額売上', '月額粗利']
    elsif type == Business::COUNT_RANK
      attributes = ['施設名', '3位以内日数', '状態']
      attributes += ['日額', '日次売上', '日次粗利'] if current_user.admin? || current_user.agent?
      attributes += ['月額売上', '月額粗利']
    elsif type == Business::BELOW_TOP_RANK
      attributes = ['日付', '案件名', '検索キーワード', '順位', '検索住所']
    end

    businesses = business_filter ? @filtered_businesses : @businesses
    businesses = businesses.where(id: params[:business_ids]) if params[:business_ids].present?
    content_csv =
      if type == Business::BELOW_TOP_RANK
        content_csv_below_rank(attributes, businesses, labels)
      else
        CSV.generate(headers: true) do |csv|
          csv << attributes
          businesses.each do |business|
            data = [business.name]
            data + business.day_top_rank_in_month(labels, type, data) if type == Business::DATA_RANK
            if type == Business::COUNT_RANK
              day_top_rank = business.day_top_rank_in_month(labels, type, data)
              data << day_top_rank
              data << convert_status(business.status)
              if current_user.admin? || current_user.agent?
                data << business.daily_unit_price
                data << business.daily_unit_price * day_top_rank
                data << business.profit_amount * day_top_rank
              end
            end
            if current_user.admin? && business_filter
              data << business.performance_month_fee
              data << business.monthly_profit_amount
            end

            csv << data
          end
        end
      end

    respond_to do |format|
      format.csv { send_data content_csv.encode(Encoding::SJIS, 'utf-8', undef: :replace),
        filename: file_name, type: 'text/csv; charset=shift_jis' }
    end
  end

  def content_csv_below_rank(attributes, businesses, labels)
    date = labels.first.to_date
    con = ActiveRecord::Base.connection
    CSV.generate(headers: true) do |csv|
      csv << attributes
      result =
        con.exec_query('select day(date), business_id, keyword_id, rank, base_location_japanese' +
          ' from meo_histories where business_id IN (' + businesses.ids.join(',')  + ')' +
          ' and year(date) = ' + date.year.to_s + ' and month(date) = ' + date.month.to_s)

      business_list = Business.where(id: businesses.ids).index_by(&:id)
      keyword_list = Keyword.where(business: businesses).index_by(&:id)
      if result.present?
        result = result.rows.sort { |a, b| a[1] <=> b[1] && a[2] <=> b[2] }
        result.each do |row|
          date_csv = date.year.to_s + '-' + date.month.to_s + '-' + row[0].to_s
          business_csv = business_list[row[1].to_i].try(:[], :name).to_s
          keyword_csv = keyword_list[row[2].to_i].try(:[], :value).to_s
          rank = row[3]
          rank = rank.to_i == 21 ? '圏外' : rank
          data = [date_csv, business_csv, keyword_csv, rank, row[4]]

          csv << data
        end
      end
    end
  end
end
