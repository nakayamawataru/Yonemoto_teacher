# == Schema Information
#
# Table name: reviews
#
#  id                :bigint           not null, primary key
#  content           :text(65535)
#  create_time       :datetime
#  deleted_at        :datetime
#  negative          :boolean          default(FALSE)
#  negative_keywords :text(65535)
#  positive          :boolean          default(FALSE)
#  positive_keywords :text(65535)
#  reply_content     :text(65535)
#  reply_update_time :datetime
#  review_reply      :string(255)
#  reviewer          :string(255)
#  star_rating       :integer
#  update_time       :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  business_id       :bigint           not null
#  review_id         :string(255)
#
# Indexes
#
#  index_reviews_on_business_id  (business_id)
#  index_reviews_on_deleted_at   (deleted_at)
#  index_reviews_on_review_id    (review_id)
#

class Review < ApplicationRecord
  # 重要なので外さないでください - Important! Do not remove!
  acts_as_paranoid

  after_create :save_sms_review

  belongs_to :business
  has_one :sms_review

  scope :cur_month, -> { where('create_time BETWEEN ? AND ?', Time.zone.now.beginning_of_month, Time.zone.now.end_of_month) }
  scope :is_positive, -> { where(positive: true) }
  scope :is_negative, -> { where(negative: true) }
  scope :not_replied, -> { where(reply_content: nil).or(where(reply_update_time: nil)) }

  REVIEW_BAD = 2
  REVIEW_GOOD = 3

  def self.convert_star_to_num(star)
    case star
    when 'ONE'
      1
    when 'TWO'
      2
    when 'THREE'
      3
    when 'FOUR'
      4
    when 'FIVE'
      5
    end
  end

  def week
    create_time.beginning_of_week.strftime("%m/%d〜")
  end

  def day
    create_time.strftime("%m/%d〜")
  end

  def month
    create_time.beginning_of_month.strftime("%m/%d〜")
  end

  def check_rating(rate, recheck=false, send_email=true)
    if self.star_rating == rate && !recheck # Return if unchanged
      return rate
    end

    if send_email && rate <= Settings.reviews.bad_rating
      ReviewMailer.bad_rating_notify(
        self.business_id,
        self.content,
        self.reviewer,
        self.create_time.try(:strftime, '%Y-%m-%d %H:%M:%S')
      ).deliver_later
    end
    rate
  end

  def check_comment(word_type, comment, recheck=false, send_email=true)
    if self.content == comment && !recheck # Return if unchanged
      return { checked: self.try(word_type.to_sym), words: try((word_type.to_s + '_keywords').to_sym).to_s.split('/') }
    end
    return { checked: false, words: [] } if business.blank?

    keywords = KeywordReview.try(word_type.to_sym)
    return { checked: false, words: [] } if keywords.blank? || comment.blank?

    words = keywords.pluck(:value).select{ |item| comment.include?(item) }
    return { checked: false, words: [] } if words.blank?

    user = business.user
    selected_words = []
    matched_words = []
    whitelists = user.admin? ? KeywordReview.try(:whitelist).where(user: nil).pluck(:value) : user.keyword_reviews.pluck(:value)
    if whitelists.present?
      whitelists.each do |whitelist|
        if comment.match?(whitelist)
          matched_words << whitelist
        end
      end
    end
    if matched_words.present?
      matched_words.each do |matched_word|
        words.each do |word|
          unless matched_word.match?(word)
            selected_words << word
          end
        end
      end
    else
      selected_words = words
    end

    have_words = selected_words.present?

    if send_email && have_words && word_type == 'negative'
      ReviewMailer.bad_comment_notify(
        self.business_id,
        selected_words,
        comment,
        self.reviewer,
        self.create_time.try(:strftime, '%Y-%m-%d %H:%M:%S')
      ).deliver_later
    end

    { checked: have_words, words: selected_words }
  end

  def self.to_csv(word_type)
    headers = ['施設名', '投稿者名', '日付', '点数', '口コミ内容']
    headers << 'ワード名' if word_type.present?
    businesses = Business.where(id: all.map(&:business_id)).index_by(&:id)
    today = Time.zone.today
    month_ranges = today.beginning_of_month.beginning_of_day..today.end_of_month.end_of_day
    total_reviews = all.size

    CSV.generate(headers: true) do |csv|
      csv << ['口コミ総数', total_reviews]
      csv << ['クチコミ平均値', total_reviews > 0 ? (all.sum(:star_rating)/total_reviews.to_f).round(1) : 0]
      csv << ['今月の口コミ', all.where(create_time: month_ranges).size]
      csv << ['ポジティブ口コミ数', all.where(positive: true).size] unless word_type == 'negative_keywords'
      csv << ['ネガティブ口コミ数', all.where(negative: true).size] unless word_type == 'positive_keywords'
      csv << []
      csv << headers
      all.each do |review|
        data = [
          businesses[review.business_id]&.name,
          review.reviewer,
          review.create_time.strftime('%Y-%m-%d %H:%M:%S'),
          review.star_rating,
          review.content.tr("\n", "")
        ]
        data << review.send(word_type).tr(" ", "") if word_type.present?

        csv << data
      end
    end
  end

  def auto_reply?
    business&.user.try(:auto_reply_reviews_restricted)
  end

  def type_review
    type = nil
    if content.present?
      type = ReplyReview.type_reviews[:less_two_stars] if star_rating <= Review::REVIEW_BAD
      type = ReplyReview.type_reviews[:greater_three_stars] if star_rating >= Review::REVIEW_GOOD
    else
      type = ReplyReview.type_reviews[:less_two_stars_no_comment] if star_rating <= Review::REVIEW_BAD
      type = ReplyReview.type_reviews[:greater_three_stars_no_comment] if star_rating >= Review::REVIEW_GOOD
    end

    type
  end

  def replied?
    reply_content.present? || reply_update_time.present?
  end

  def as_json(options = {})
    super(options).merge({
      text_reply_update_time: (reply_update_time ? reply_update_time.strftime('%Y-%m-%d %H:%M:%S') : '')
    })
  end

  def self.recheck_comment
    where.not(content: '').each do |r|
      check_comment_positive = r.check_comment('positive', r.content, true, false)
      check_comment_negative = r.check_comment('negative', r.content, true, false)
      r.positive = check_comment_positive[:checked]
      r.negative = check_comment_negative[:checked]
      r.positive_keywords = check_comment_positive[:words].join(' / ')
      r.negative_keywords = check_comment_negative[:words].join(' / ')
      r.save
    end
  end

  def update_review_from_google_api(data)
    self.reviewer = data['reviewer'].try(:[], 'displayName').to_s
    review_comment = data.try(:[], 'comment').to_s
    is_recent_review = new_record? && (data['createTime'].to_time > (Time.zone.now - 1.day))

    self.create_time = data['createTime'].to_time
    self.update_time = data['updateTime'].to_time
    check_comment_positive = check_comment('positive', review_comment, false, is_recent_review)
    check_comment_negative = check_comment('negative', review_comment, false, is_recent_review)
    self.positive = check_comment_positive[:checked]
    self.negative = check_comment_negative[:checked]
    self.positive_keywords = check_comment_positive[:words].join(' / ')
    self.negative_keywords = check_comment_negative[:words].join(' / ')
    self.content = review_comment
    self.star_rating = check_rating(Review.convert_star_to_num(data['starRating']), false, is_recent_review)

    review_reply = data.try(:[], 'reviewReply')
    if review_reply.present?
      self.reply_content = review_reply.try(:[], 'comment').to_s
      self.reply_update_time = review_reply['updateTime'].to_time
    end
    self.save
  end

  private

  def save_sms_review
    sms_review = SmsReview.find_or_initialize_by(business_id: business_id, review_id: id)
    sms_review.username = reviewer
    sms_review.save
  end
end
