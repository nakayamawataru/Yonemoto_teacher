# == Schema Information
#
# Table name: businesses
#
#  id                           :bigint           not null, primary key
#  address                      :string(255)
#  base_address                 :string(255)
#  base_ip_address              :string(255)
#  base_lat                     :decimal(15, 10)
#  base_long                    :decimal(15, 10)
#  bid                          :string(255)
#  building                     :string(255)
#  daily_unit_price             :integer          default(0)
#  default_review_url           :string(255)
#  deleted_at                   :datetime
#  e_park_url                   :string(255)
#  ekiten_url                   :string(255)
#  facebook_url                 :string(255)
#  gmail                        :string(255)
#  gmb_connect_status           :integer
#  google_account_refresh_token :string(255)
#  hotpepper_url                :string(255)
#  instagram_url                :string(255)
#  keyword_count                :integer          default(0)
#  last_connected_at            :datetime
#  logo_review_message          :string(255)
#  map_url                      :string(255)
#  monthly_profit_amount        :integer          default(0)
#  name                         :string(255)      not null
#  pattern_review               :integer          default(2)
#  performance_fee              :integer          default(0)
#  performance_month_fee        :integer
#  postal_code                  :string(255)
#  prefecture                   :string(255)
#  primary_phone                :string(255)
#  profile_description          :text(65535)
#  profit_amount                :integer          default(0)
#  review_url                   :string(255)
#  show_qa                      :boolean          default(FALSE)
#  status                       :integer          default("active"), not null
#  time_crawler                 :string(255)
#  website_url                  :string(255)
#  yahoo_place_url              :string(255)
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  google_account_id            :string(255)
#  location_id                  :string(255)
#  owner_id                     :bigint
#  place_id                     :string(255)
#  user_id                      :bigint           not null
#
# Indexes
#
#  index_businesses_on_deleted_at  (deleted_at)
#  index_businesses_on_owner_id    (owner_id)
#  index_businesses_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

class Business < ApplicationRecord
  # 重要なので外さないでください - Important! Do not remove!
  acts_as_paranoid

  mount_uploader :logo_review_message, ImageUploader

  DEFAULT_UPDATABLE_ATTRIBUTES = (%i[user_id name base_address status primary_phone postal_code performance_fee performance_month_fee
                                     time_crawler daily_unit_price profit_amount monthly_profit_amount e_park_url ekiten_url
                                     facebook_url hotpepper_url instagram_url yahoo_place_url default_review_url logo_review_message pattern_review] <<
                                     [keywords_attributes: [:id, :value, :_destroy]] <<
                                     [owner_attributes: [:id, :name, :email, :company, :phone_number, :password, :role, :expire_at]] <<
                                     [benchmark_business_attributes: [:id, :name, :_destroy]] <<
                                     [memos_attributes: [:id, :title, :date, :user_id, :_destroy]]
                                  ).flatten!
  ALLOW_EMPTY_ATTRIBUTES = %i[e_park_url ekiten_url facebook_url hotpepper_url instagram_url yahoo_place_url default_review_url logo_review_message]

  enum status: { active: 1, stopped: 2, canceled: 3 }
  enum gmb_connect_status: { connecting: 1, connected: 2, not_match: 3, api_errors: 4 }
  GMB_STATUS = { connecting: "GMB連携中", connected: "GMB連携済み", not_match: "GMB連携失敗", api_errors: "GoogleAPIエラー" }.with_indifferent_access
  GMB_INSIGHT_MAX_RANGE = 17 # Maximum can get 18 months = current month + 17 months ago

  has_many :messages, dependent: :destroy
  has_many :sms_reviews, dependent: :destroy
  has_many :coupons, dependent: :destroy
  has_many :monthly_fees, dependent: :destroy
  has_many :insights, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :keywords, dependent: :destroy
  has_many :meo_histories, dependent: :destroy
  has_one :simple_qr, dependent: :destroy, class_name: SettingQr::Simple.name
  has_one :normal_qr, dependent: :destroy, class_name: SettingQr::Normal.name
  has_one :sms_qr, dependent: :destroy, class_name: SettingQr::Sms.name
  has_one :anonymous_qr, dependent: :destroy, class_name: SettingQr::Anonymous.name
  has_one :setting_sms, dependent: :destroy
  belongs_to :user
  belongs_to :owner, optional: true, foreign_key: :owner_id, class_name: User.name
  has_many :keyword_crawler_errors, dependent: :delete_all
  has_many :benchmark_business, dependent: :destroy
  has_many :total_monthly_fees, dependent: :destroy
  has_many :keywords_histories, dependent: :destroy
  has_many :category_business, dependent: :destroy
  has_many :categories, through: :category_business
  has_many :memos, dependent: :destroy
  has_many :reply_reviews, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :qa_reviews, dependent: :destroy

  validates :user, presence: true
  validates :name, presence: true
  validates :primary_phone, presence: true
  validate :valid_time_crawler, on: :update

  accepts_nested_attributes_for :keywords, allow_destroy: true,
                                reject_if: Proc.new { |att| att[:value].blank? }
  accepts_nested_attributes_for :owner, allow_destroy: true, reject_if: proc { |attributes| attributes['name'].blank? && attributes['email'].blank? }
  accepts_nested_attributes_for :benchmark_business, allow_destroy: true, reject_if: Proc.new { |att| att[:name].blank? }
  accepts_nested_attributes_for :memos, allow_destroy: true, reject_if: Proc.new { |att| att[:title].blank? || att[:date].blank? }

  scope :in_top_3, -> { joins(:meo_histories).where('meo_histories.rank <= ?', 3).group('businesses.id').length }
  scope :connecting_before, ->(time) { where("last_connected_at <= ?", time) }

  # before_validation :retrieve_info
  before_validation :update_owner_restricted
  after_save :update_monthly_fee
  after_commit :update_bid, on: :create
  before_destroy :delete_owner

  geocoded_by :base_address, latitude: :base_lat, longitude: :base_long
  after_validation :geocode, if: ->(obj){ obj.base_address.present? and obj.will_save_change_to_base_address? }
  scope :not_managed_by_agent_and_agent_meo_check, -> do
    agent_ids = User.agent.ids + User.agent_meo_check.ids
    user_ids = User.by_agent_ids(agent_ids).ids
    where.not(user_id: agent_ids + user_ids)
  end
  scope :not_managed_by_agent, -> do
    agent_ids = User.agent.ids
    user_ids = User.by_agent_ids(agent_ids).ids
    where.not(user_id: agent_ids + user_ids)
  end
  scope :managed_by_agent_meo_check_with_plan, ->(plan_ids) do
    agent_ids = User.agent_meo_check.where(plan_id: plan_ids).ids
    user_ids = User.by_agent_ids(agent_ids).ids
    where(user_id: agent_ids + user_ids)
  end
  scope :not_managed_by_demo_entry_users, -> do
    user_ids = User.demo_user.where(plan_id: Plan::ENTRY).ids
    where.not(user_id: user_ids)
  end

  DATA_RANK = 1
  COUNT_RANK = 2
  BELOW_TOP_RANK = 3

  def self.retrieve_rank_all
    active.each do |business|
      not_have_high_rank = business.meo_histories.where("rank <= ?", Settings.meo_history.rank_in_top).blank?
      business.keywords.each(&:get_ranking)
      business.update_monthly_fee
      next unless not_have_high_rank
      RankingMailer.high_ranking_notify(business).deliver_later if business.meo_histories.where("rank <= ?", Settings.meo_history.rank_in_top).present?
    end
  end

  def self.retrieve_reviews_all
    # Old solution
    # active.where.not(location_id: nil).each(&:fetch_reviews)

    # New solution
    gmb_accounts = active.where.not(location_id: nil).pluck(:gmail, :google_account_id, :google_account_refresh_token).uniq
    gmb_accounts.each{ |gmb_account| Business.fetch_reviews_batch(*gmb_account) }
  end

  def self.retrieve_insights_data
    active.where.not(location_id: nil).each(&:fetch_insights)
  end

  def average_rating
    return 0 if reviews.blank?
    (reviews.sum(:star_rating) / reviews.count.to_f).round(1)
  end

  def fetch_reviews
    unless location_id.present?
      errors.add(:base, "案件IDが欠けています。GMB連携してください。")
      return false
    end

    reviews_array = []
    fetch_review_error = false
    next_page_token = ''
    client = GoogleBusinessApi.new(google_account_id: google_account_id, google_account_refresh_token: google_account_refresh_token)
    loop do
      result = client.list_reviews(location_id, next_page_token)
      fetch_review_error = result['error'].present?
      break if result.blank? || result.try(:[], 'reviews').blank?
      reviews_array << result['reviews']
      next_page_token = result['nextPageToken']
      break if next_page_token.blank?
    end

    import_reviews(reviews_array.flatten) unless fetch_review_error
  rescue Exception => e
    logger.error "There was an exception - #{e.class}(#{e.message})"
    logger.error e.backtrace.join("\n")
    errors.add(:base, "ご指定のメールアドレスの権限の問題で現在口コミが取得できません。1時間ほど時間を試してください。")
    return false
  end

  def self.fetch_reviews_batch(gmail, google_account_id, google_account_refresh_token)
    client = GoogleBusinessApi.new(google_account_id: google_account_id, google_account_refresh_token: google_account_refresh_token)
    target_businesses = Business.active.where.not(location_id: nil).where(gmail: gmail,
      google_account_id: google_account_id, google_account_refresh_token: google_account_refresh_token)
    business_location_ids = target_businesses.pluck(:location_id)
    return unless business_location_ids.any?

    business_location_ids = business_location_ids.each_slice(20).to_a # Request API for 20 business per request
    business_location_ids.each do |location_ids|
      reviews_array = []
      fetch_review_error = false
      next_page_token = ''
      loop do
        result = client.list_reviews_batch(location_ids, next_page_token)
        fetch_review_error = result['error'].present?
        break if result.blank? || result.try(:[], 'locationReviews').blank?
        reviews_array << result['locationReviews']
        next_page_token = result['nextPageToken']
        break if next_page_token.blank?
      end

      Business.import_reviews_batch(reviews_array.flatten, target_businesses) unless fetch_review_error
    end
  rescue Exception => e
    logger.error "There was an exception - #{e.class}(#{e.message})"
    logger.error e.backtrace.join("\n")
    return false
  end

  def clear_insights
    month_ins = []
    (1..GMB_INSIGHT_MAX_RANGE).each do |i|
      month_ins << i.months.ago.strftime('%Y-%m')
    end
    insights.where(month_in: month_ins).delete_all
  end

  def fetch_insights
    return unless location_id.present?

    client = GoogleBusinessApi.new(google_account_id: google_account_id, google_account_refresh_token: google_account_refresh_token)
    current_month = Time.zone.now.strftime('%Y-%m')
    # Don't get data of current month
    (1..GMB_INSIGHT_MAX_RANGE).to_a.reverse.each do |i|
      time = i.months.ago
      month_in = time.strftime('%Y-%m')
      not_current_month = month_in != current_month
      next if not_current_month && self.insights.where(month_in: month_in, is_completed: true).count == 10 # 10 Metric
      range_times = [time.beginning_of_month.rfc3339, time.end_of_month.rfc3339]
      response = client.fetch_insights("ALL", range_times, self.location_id, 'AGGREGATED_TOTAL')
      next if response['error'].present?
      metric_data = response.try(:[], 'locationMetrics').present? ? response['locationMetrics'].first.try(:[], 'metricValues') : []
      import_search_method_data(metric_data, month_in, not_current_month)
      import_display_location_data(metric_data, month_in, not_current_month)
      import_action_data(metric_data, month_in, not_current_month)
      import_photo_views_data(metric_data, month_in, not_current_month)
    end
  rescue Exception => e
    logger.error "There was an exception - #{e.class}(#{e.message})"
    logger.error e.backtrace.join("\n")
  end

  def update_monthly_fee
    monthly_fee = MonthlyFee.find_or_initialize_by(business: self, month_in: Time.zone.now.strftime('%Y-%m'))
    monthly_fee.value = self.performance_fee
    monthly_fee.save
  end

  def update_bid
    return if bid.present?

    token = SecureRandom.hex(16)
    while Business.find_by(bid: token) do
      token = SecureRandom.hex(16)
    end

    self.update_columns(bid: token)
  end

  def update_owner_restricted
    return unless owner.present?
    return if owner.id.present?
    # Update owner restricted to match business user
    owner.restricted = user.restricted
    owner.coupon_restricted = user.coupon_restricted
    owner.gmb_restricted = user.gmb_restricted
  end

  def update_ranking_keywords(keywords, date)
    keywords.each do |key|
      keyword = Keyword.find_by(id: key['id'])
      keyword.update_ranking(key, date) if keyword
    end
  end

  def base_location_crawler
    location = BaseLocation.find_by(base_address: base_address)
    if location
      location.base_address_english.present? ? location.base_address_english :
        location.base_address
    else
      nil
    end
  end

  def ranking_keywords(date)
    results = []
    keywords.each do |keyword|
      result = keyword.current_rank date
      results.push result
    end

    results
  end

  def update_info(location)
    self.name ||= location['locationName']
    self.location_id = location['name'].split('/').last
    self.primary_phone = location['primaryPhone']
    self.website_url = location['websiteUrl']
    self.place_id = location['locationKey']['placeId']
    self.base_lat = location['latlng'].try(:[], 'latitude').to_f
    self.base_long = location['latlng'].try(:[], 'longitude').to_f
    self.map_url = location['metadata']['mapsUrl']
    self.review_url = location['metadata']['newReviewUrl']
    self.postal_code = location['address'].try(:[], 'postalCode').to_s
    self.prefecture = location['address'].try(:[], 'administrativeArea').to_s
    # self.base_address = self.prefecture + location['address'].try(:[], 'addressLines').try(:join).to_s
    self.profile_description = location['profile'].try(:[], 'description').to_s
    self.gmb_connect_status = Business.gmb_connect_statuses[:connected]
    update_category(location)
  end

  def day_top_rank_in_month(days, type, data=[])
    month = days.first.to_date.month
    year = days.first.to_date.year
    con = ActiveRecord::Base.connection
    result =
      con.exec_query('select day(date), min(rank) as min_rank' +
      ' from meo_histories where business_id = ' + id.to_s +
      ' and  year(date) = ' + year.to_s + ' and month(date) = ' +
      month.to_s + '  group by date')

    count = 0
    for i in 1..days.count
      rank = result.rows.map {|r| r[1] if r[0] == i}.compact.first
      data << (rank && rank.to_i <= 3 ? '◯' : '-') if type == DATA_RANK
      count += 1 if (rank && rank.to_i <= 3) if type == COUNT_RANK
    end

    return data if type == DATA_RANK
    return count if type == COUNT_RANK
  end

  def insights_by_month(month)
    insights.where(month_in: month.strftime('%Y-%m'))
  end

  def update_category(location)
    primary_category = location['primaryCategory']
    additional_categories = location['additionalCategories']
    import_category(primary_category, CategoryBusiness.category_types[:primary]) if primary_category.present?
    if additional_categories.present?
      additional_categories.each do |addition|
        import_category(addition, CategoryBusiness.category_types[:addition])
      end
    end
  end

  def reformat(string)
    string.gsub('-', '').gsub('_', '').strip
  end

  def update_google_business(location_id)
    return unless connecting?
    GoogleConnectApiJob.perform_async(self.id, location_id)
  end

  def gmb_status_ja
    GMB_STATUS[gmb_connect_status]
  end

  def google_locations
    client = GoogleBusinessApi.new(google_account_id: google_account_id, google_account_refresh_token: google_account_refresh_token)
    locations = []
    next_page_token = ''
    loop do
      result = client.list_locations next_page_token
      break if result.blank? || result.try(:[], 'locations').blank?
      locations += result['locations']
      next_page_token = result['nextPageToken']
      break if next_page_token.blank?
    end
    locations
  end

  def get_google_location(location_id)
    client = GoogleBusinessApi.new(google_account_id: google_account_id, google_account_refresh_token: google_account_refresh_token)
    client.get_location(location_id)
  end

  def csv_template_meo_histories
    headers = ['案件名', 'キーワード', '日', '順位', '案件ID', 'キワードID']
    CSV.generate(headers: true) do |csv|
      csv << headers
      keywords.each do |keyword|
        data = [
          name,
          keyword&.value,
          Time.zone.today.try(:strftime, '%Y-%m-%d'),
          '',
          id,
          keyword.id
        ]

        csv << data
      end
    end
  end

  def review_services_url_exists?
    default_review_url.present? || e_park_url.present? || ekiten_url.present? || facebook_url.present? ||
      hotpepper_url.present? || instagram_url.present? || yahoo_place_url.present? || review_url.present?
  end

  private

  def import_search_method_data(metric_data, month_in, is_completed)
    queries_direct = Insight.find_or_initialize_by(business: self, month_in: month_in, data_type: Insight.data_types[:queries_direct])
    queries_direct.value = metric_data.select{|item| item['metric'] == 'QUERIES_DIRECT'}.first.try(:[], 'totalValue').try(:[], 'value').to_i
    queries_direct.is_completed = is_completed
    queries_direct.save

    queries_indirect = Insight.find_or_initialize_by(business: self, month_in: month_in, data_type: Insight.data_types[:queries_indirect])
    queries_indirect.value = metric_data.select{|item| item['metric'] == 'QUERIES_INDIRECT'}.first.try(:[], 'totalValue').try(:[], 'value').to_i
    queries_indirect.is_completed = is_completed
    queries_indirect.save

    queries_chain = Insight.find_or_initialize_by(business: self, month_in: month_in, data_type: Insight.data_types[:queries_chain])
    queries_chain.value = metric_data.select{|item| item['metric'] == 'QUERIES_CHAIN'}.first.try(:[], 'totalValue').try(:[], 'value').to_i
    queries_chain.is_completed = is_completed
    queries_chain.save
  end

  def import_display_location_data(metric_data, month_in, is_completed)
    view_search = Insight.find_or_initialize_by(business: self, month_in: month_in, data_type: Insight.data_types[:view_search])
    view_search.value = metric_data.select{|item| item['metric'] == 'VIEWS_SEARCH'}.first.try(:[], 'totalValue').try(:[], 'value').to_i
    view_search.is_completed = is_completed
    view_search.save

    view_maps = Insight.find_or_initialize_by(business: self, month_in: month_in, data_type: Insight.data_types[:view_maps])
    view_maps.value = metric_data.select{|item| item['metric'] == 'VIEWS_MAPS'}.first.try(:[], 'totalValue').try(:[], 'value').to_i
    view_maps.is_completed = is_completed
    view_maps.save
  end

  def import_action_data(metric_data, month_in, is_completed)
    action_website = Insight.find_or_initialize_by(business: self, month_in: month_in, data_type: Insight.data_types[:action_website])
    action_website.value = metric_data.select{|item| item['metric'] == 'ACTIONS_WEBSITE'}.first.try(:[], 'totalValue').try(:[], 'value').to_i
    action_website.is_completed = is_completed
    action_website.save

    action_driving_direction = Insight.find_or_initialize_by(business: self, month_in: month_in, data_type: Insight.data_types[:action_driving_direction])
    action_driving_direction.value = metric_data.select{|item| item['metric'] == 'ACTIONS_DRIVING_DIRECTIONS'}.first.try(:[], 'totalValue').try(:[], 'value').to_i
    action_driving_direction.is_completed = is_completed
    action_driving_direction.save

    action_phone = Insight.find_or_initialize_by(business: self, month_in: month_in, data_type: Insight.data_types[:action_phone])
    action_phone.value = metric_data.select{|item| item['metric'] == 'ACTIONS_PHONE'}.first.try(:[], 'totalValue').try(:[], 'value').to_i
    action_phone.is_completed = is_completed
    action_phone.save
  end

  def import_photo_views_data(metric_data, month_in, is_completed)
    photo_views_merchant = Insight.find_or_initialize_by(business: self, month_in: month_in, data_type: Insight.data_types[:photo_views_merchant])
    photo_views_merchant.value = metric_data.select{|item| item['metric'] == 'PHOTOS_VIEWS_MERCHANT'}.first.try(:[], 'totalValue').try(:[], 'value').to_i
    photo_views_merchant.is_completed = is_completed
    photo_views_merchant.save

    photo_views_customer = Insight.find_or_initialize_by(business: self, month_in: month_in, data_type: Insight.data_types[:photo_views_customer])
    photo_views_customer.value = metric_data.select{|item| item['metric'] == 'PHOTOS_VIEWS_CUSTOMERS'}.first.try(:[], 'totalValue').try(:[], 'value').to_i
    photo_views_customer.is_completed = is_completed
    photo_views_customer.save
  end

  def import_reviews(data_array)
    review_id_list = []
    data = data_array.reduce(Array.new) do |a, e|
      review = reviews.find_or_initialize_by(review_id: e['reviewId'])
      review.update_review_from_google_api(e)
      review_id_list << review.id
    end

    # Remove deleted review
    reviews.where.not(id: review_id_list).destroy_all
  end

  def self.import_reviews_batch(data_array, target_businesses)
    formatted_data = data_array.flatten.group_by{|v| v['name']}
    formatted_data.keys.each do |key|
      google_account_id = key.split('/')[1]
      location_id = key.split('/')[3]
      businesses = target_businesses.where(google_account_id: google_account_id, location_id: location_id)

      next unless businesses.present?

      data = formatted_data[key]
      businesses.each do |business|
        review_id_list = []
        data.each do |item|
          e = item['review']
          review = business.reviews.find_or_initialize_by(review_id: e['reviewId'])
          review.update_review_from_google_api(e)
          review_id_list << review.id
        end

        # Remove deleted review
        business.reviews.where.not(id: review_id_list).destroy_all
      end
    end
  end

  def retrieve_info
    return if self.primary_phone.blank?
    return unless self.will_save_change_to_primary_phone? || self.will_save_change_to_postal_code?

    client = GoogleBusinessApi.new(google_account_id: google_account_id, google_account_refresh_token: google_account_refresh_token)
    locations = []
    next_page_token = ''
    loop do
      result = client.list_locations next_page_token
      break if result.blank? || result.try(:[], 'locations').blank?
      locations += result['locations']
      next_page_token = result['nextPageToken']
      break if next_page_token.blank?
    end
    return if locations.blank?

    mapped_locations = locations.select { |l| l['primaryPhone'].present? && reformat(l['primaryPhone']) == reformat(self.primary_phone) }
    if mapped_locations.present?
      if self.postal_code.present? && mapped_locations.count > 1
        location = mapped_locations.select { |l| l['address']['postalCode'].present? && reformat(l['address']['postalCode']) == reformat(self.postal_code) }.first
      else
        location = mapped_locations.first
      end
    end
    return if location.blank?
    update_info(location)
  rescue Exception => e
    logger.error "There was an exception - #{e.class}(#{e.message})"
    logger.error e.backtrace.join("\n")
  end

  def import_category(category_api, category_type)
    category = Category.find_or_create_by(name: category_api["displayName"], gcid: category_api["categoryId"])
    category_business_primary = CategoryBusiness.find_by(business: self, category_type: category_type)
    if category_type == CategoryBusiness.category_types[:primary] && category_business_primary
      unless category_business_primary&.category == category
        category_business_primary.business_id = nil
        category_business_primary.save
        CategoryBusiness.find_or_create_by(business: self, category: category, category_type: category_type)
      end
    else
      CategoryBusiness.find_or_create_by(business: self, category: category, category_type: category_type)
    end
  end

  def delete_owner
    owner&.destroy
  end

  def valid_time_crawler
    if time_crawler.to_s > '21:00'
      errors.add(:time_crawler, '00〜21時までの時間帯をご入力してください')
    end
  end
end
