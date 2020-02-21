# == Schema Information
#
# Table name: keywords
#
#  id          :bigint           not null, primary key
#  color       :string(255)      not null
#  deleted_at  :datetime
#  value       :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  business_id :bigint           not null
#
# Indexes
#
#  index_keywords_on_business_id  (business_id)
#  index_keywords_on_deleted_at   (deleted_at)
#
# Foreign Keys
#
#  fk_rails_...  (business_id => businesses.id)
#

class Keyword < ApplicationRecord
  # 重要なので外さないでください - Important! Do not remove!
  acts_as_paranoid

  belongs_to :business
  has_many :meo_histories, dependent: :delete_all
  has_many :keyword_crawler_errors, dependent: :delete_all
  has_many :meo_benchmark_business_histories, dependent: :delete_all

  before_create :generate_color

  COLORS = ["#0077CC", "#0014CC", "#5504CC", "#BB02CC", "#CC0077", "#CC0011",
    "#CC5501", "#CCBB01", "#77CC01", "#12CC01", "#02CC55", "#00CCBB"]

  def get_ranking
    return if meo_histories.find_by(business: business, date: Date.today).present?
    client = PlacesApi.new business, value
    result = client.retrieve_ranking
    # RankingMailer.fetch_ranking_error_notify(self, result).deliver_later and return if result['results'].blank?
    rank = get_index_of_business(result['results']) || Settings.meo_history.out_of_range
    meo_histories.create(business: business, date: Date.today, rank: rank,
                         base_location: business.base_address)
  rescue Exception => e
    logger.error "There was an exception - #{e.class}(#{e.message})"
    logger.error e.backtrace.join("\n")
  end

  def get_ranking_arr_by(params)
    return [] if params[:month].blank? && params[:day_number].blank?
    if params[:month].present?
      month_as_date = params[:month].to_date
      range_time = month_as_date.beginning_of_month..month_as_date.end_of_month
    elsif params[:day_number].present?
      range_time = params[:day_number].to_i.days.ago.to_date..Date.today
    end

    with_rank = params[:within_rank].present? ? params[:within_rank] : 'all'
    items_event = meo_histories.where(business: business, date: range_time)
    if with_rank != 'all'
      items_event = items_event.where('rank <= ?', with_rank)
    end
    items_event.try(:pluck, [:date, :rank])
  end

  def update_ranking(key, date)
    date_crawler = date.to_date
    unless meo_histories.find_by(business: business,date: date_crawler).present?
      rank = key["data"]["rank"].to_i
      rank_benchmark_business = key["data"]["rankBenchmarkBusiness"] || []
      images = key["data"]["images"]
      base_location = key["base_location"]
      base_location_japanese = key['base_location_japanese']

      if key["data"]["error"].present?
        times_keyword_error_last =
          KeywordCrawlerError.times_keyword_error_last(business, self, date_crawler)
        KeywordCrawlerError.create(business: business, keyword: self,
          date: date_crawler, images: images, times: times_keyword_error_last + 1)
      else
        meo = meo_histories.create(business: business, date: date_crawler,
          rank: rank, base_location: base_location, images: images,
          base_location_japanese: base_location_japanese)

        rank_benchmark_business.each do |rankBB|
          meo_benchmark_business_histories.create(
            benchmark_business_id: rankBB["id"],
            rank: rankBB["rank"],
            date: date_crawler
          )
        end

        sent_mail_out_rank(meo)
      end
    end
  end

  def current_rank(date)
    meo_histories.where(business: business, date: date).first
  end

  def max_rank_in_month(date)
    meo_histories.where(business: business, date: ((date.beginning_of_month)..(date.end_of_month)).to_a).pluck(:rank).min
  end

  # Benchmark Business
  def get_ranking_benchmark_business(benchmark_business, params)
    return [] if params[:month].blank? && params[:day_number].blank?
    if params[:month].present?
      month_as_date = params[:month].to_date
      range_time = month_as_date.beginning_of_month..month_as_date.end_of_month
    elsif params[:day_number].present?
      range_time = params[:day_number].to_i.days.ago.to_date..Date.today
    end

    with_rank = params[:within_rank].present? ? params[:within_rank] : 'all'
    items_event = meo_benchmark_business_histories.where(benchmark_business: benchmark_business, date: range_time)
    if with_rank != 'all'
      items_event = items_event.where('rank <= ?', with_rank)
    end
    items_event.try(:pluck, [:date, :rank])
  end

  private

  def get_index_of_business results
    item = results.find{ |item_h| item_h['name'] == business.name || item_h['place_id'] == business.place_id.to_s }
    return if item.blank?
    results.index(item).to_i + 1
  end

  def generate_color
    self.color = "#%06x" % (rand * 0x1000000)
  end

  def sent_mail_out_rank(meo)
    meo_pre = meo.meo_previous
    if (meo_pre && meo_pre.top_rank? && meo.in_rank? && !meo.top_rank?) ||
      (meo_pre && meo_pre.in_rank? && !meo.in_rank?)
      CrawlerMailer.out_rank(meo).deliver_later
    end
  end
end
