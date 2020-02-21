class BusinessCrawler
  def self.retrieve_rank_all_lamda
    keyword_ids_crawlered =
      MeoHistory.where(date: Date.today).pluck(:keyword_id).uniq
    keywords_need_crawlered = Keyword.where.not(id: keyword_ids_crawlered)
    businesses = Business.active.where(id: keywords_need_crawlered.map(&:business_id).uniq)
      .where('time_crawler IS NULL OR time_crawler < ?', Time.zone.now.strftime('%H:%M'))

    businesses.each do |business|
      if BaseLocation.exist_base_location? business.base_address
        keyword_need_crawlers =
          business.keywords.where(id: keywords_need_crawlered.ids)
        if keyword_need_crawlers.present?
          CrawlerLamda.get_instance.crawler business, keyword_need_crawlers
        end
      else
        # CrawlerMailer.set_base_location(business).deliver_later
      end
    end

  rescue => e
    CrawlerMailer.warning_auto_crawler_rank_keyword(e.message, e.backtrace).deliver_later
  end

  def self.retrieve_rank_all_crawler
    dynamo = Aws::DynamoDB::Client.new
    items = dynamo.scan({table_name: ENV['DYNAMO_DB_TABLE']}).items
    date_crawler = ''
    items.each do |item|
      data = JSON.parse item['value']
      date_crawler = data["date"] unless date_crawler.present?
      keywords = data["keywords"]
      business = Business.find_by(id: data["business"]["id"])
      params = {
        table_name: ENV['DYNAMO_DB_TABLE'],
        key: {
          key: item["key"]
        }
      }
      dynamo.delete_item(params)

      if business
        not_have_high_rank =
          business.meo_histories.where("rank <= ?",
            Settings.meo_history.rank_in_top).blank?
        business.update_ranking_keywords keywords, data["date"]
        business.update_monthly_fee
        next unless not_have_high_rank
        if business.meo_histories.where("rank <= ?",
          Settings.meo_history.rank_in_top).present?
          RankingMailer.high_ranking_notify(business).deliver_later
        end
      end
    end

    unless items.map{|i| JSON.parse(i['value'])['keywords']
      .select{|k| k["data"]["error"].present?}}.reject(&:empty?).present?
      KeywordCrawlerError.where(date: Date.today).delete_all
    end
    last_time_error =
      KeywordCrawlerError.where(date: Date.today).last.try(:times).to_i
    error_count = ENV.fetch('TIMES_SEND_MAIL_ERROR_CRAWLER', 0)
    if last_time_error >= error_count.to_i
      CrawlerMailer.warning_crawler_keyword(last_time_error).deliver_later
    end

    retrieve_rank_category(date_crawler.to_date)
    KeywordsHistory.count_keyword_from_meo_history
  rescue => e
    CrawlerMailer.warning_auto_crawler_rank_keyword(e.message, e.backtrace).deliver_later
  end

  def self.crawler_keyword_fail(date=Date.today, fix_data_missing=false, targets=[])
    business_ids = []
    business_keyword_fails = []
    business_not_base_locations = []
    keyword_ids_crawlered =
      MeoHistory.where(date: date).pluck(:keyword_id).uniq
    keywords_need_crawlered = Keyword.where.not(id: keyword_ids_crawlered)
    # businesses = keywords_need_crawlered.map{|k| k.business if k.business.active?}.compact.uniq
    businesses = Business.active.where(id: keywords_need_crawlered.map(&:business_id).uniq)
    businesses = businesses.where(id: targets) if targets.any?
    businesses.each do |business|
      if BaseLocation.exist_base_location? business.base_address
        keyword_need_crawlers =
          business.keywords.where(id: keywords_need_crawlered.ids)
        if keyword_need_crawlers.present?
          item = {
            business: business,
            keywords: keyword_need_crawlers
          }
          business_ids << business.id
          business_keyword_fails.push item
          if fix_data_missing
            update_data_crawler_missing(date, business, keyword_need_crawlers)
          end
        end
      else
        location = {
          business: business
        }

        business_not_base_locations.push location
      end
    end
    {
      business_ids: business_ids,
      business_keyword_fails: business_keyword_fails,
      business_not_base_locations: business_not_base_locations
    }
  end

  def self.delete_images_error_s3
    start_date_delete = Time.now.last_month.beginning_of_month.to_date
    end_date_delete = Time.now.last_month.end_of_month.to_date

    s3 = Aws::S3::Resource.new
    (start_date_delete..end_date_delete).each do |day|
      folder = 'meo_tools/crawlers-error/' + day.strftime('%Y-%m-%d')
      objects = s3.bucket(ENV['AWS_S3_BUCKET']).objects({prefix: folder})
      objects.batch_delete!
    end

  rescue => e
    CrawlerMailer.warning_auto_crawler_rank_keyword(e.message, e.backtrace).deliver_later
  end

  def self.update_data_crawler_missing(date, business, keywords)
    keywords.each do |keyword|
      meo_origin = MeoHistory.find_by(date: date - 1.day, business: business, keyword: keyword) ||
                    MeoHistory.find_by(date: date + 1.day, business: business, keyword: keyword)
      if meo_origin
        meo_new = meo_origin.dup
        meo_new.date = date
        meo_new.save
      end
    end
  end

  def self.retrieve_rank_category(date)
    if date.present?
      gcids = Category.distinct.pluck(:gcid)
      gcids.each do |gcid|
        categories =  Category.where(gcid: gcid)
        business_ids = categories.inject([]) { |ids, c|  ids + c.businesses.active.ids }.uniq
        ranks = MeoHistory.where(business_id: business_ids, date: date).pluck(:rank)
        rank_abs = caculate_rank(ranks)
        save_category_rank_history(date, gcid, rank_abs)
      end

      ranks_all = MeoHistory.where(date: date).pluck(:rank)
      save_category_rank_history(date, 'all', caculate_rank(ranks_all))
    end
  end

  def self.caculate_rank(ranks)
    sum_ranks = ranks.inject(0) { |sum, r|  sum + r.to_i }
    ranks.count.positive? ? (sum_ranks.to_f/ranks.count).round(2) : 0
  end

  def self.save_category_rank_history(date, gcid, rank_abs)
    rank_history = CategoryRankHistory.find_or_create_by(date: date, gcid: gcid)
    rank_history.update(rank: rank_abs)
  end
end
