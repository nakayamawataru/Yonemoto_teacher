# == Schema Information
#
# Table name: posts
#
#  id                  :bigint           not null, primary key
#  action_phone_number :string(255)
#  action_type         :string(255)
#  action_url          :string(255)
#  auto_post           :boolean          default(FALSE)
#  coupon_code         :string(255)
#  end_date            :datetime
#  image               :string(255)
#  post_type           :integer          default("what_news")
#  redeem_online_url   :string(255)
#  start_date          :datetime
#  status              :integer          default("pending")
#  summary             :text(65535)
#  terms_conditions    :text(65535)
#  time_post           :datetime
#  title               :text(65535)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  business_id         :integer
#  local_post_id       :string(255)
#

class Post < ApplicationRecord
  mount_uploader :image, ImageUploader

  DEFAULT_UPDATABLE_ATTRIBUTES =
    %i[action_type action_url auto_post coupon_code end_date image post_type
      redeem_online_url start_date summary terms_conditions time_post title business_id]

  validates :time_post, presence: true, if: Proc.new { |p| p.auto_post }
  validates :summary, presence: true, if: Proc.new { |p| p.what_news? }
  validates :title, presence: true, if: Proc.new { |p| p.event? || p.coupon? }
  validates :start_date, presence: true, if: Proc.new { |p| p.event? || p.coupon? }
  validates :end_date, presence: true, if: Proc.new { |p| p.event? || p.coupon? }
  validates :action_url, presence: true, if: Proc.new { |p| ['CALL', 'N0_ACTION'].exclude? p.action_type }
  validate :greater_than_current_time
  validate :action_url_valid?
  validate :redeem_online_url_valid?


  belongs_to :business

  enum post_type: { what_news: 1, event: 2, coupon: 3 }
  enum status: { successed: 1, failed: 2, pending: 3 }

  def publish
    return unless business.location_id.present?
    client = GoogleBusinessApi.new(google_account_id: business.google_account_id,
      google_account_refresh_token: business.google_account_refresh_token)
    message = nil
    response =
      if what_news?
        client.post_what_news(business.location_id, self)
      elsif event?
        client.post_event(business.location_id, self)
      elsif coupon?
        client.post_coupon(business.location_id, self)
      end

    if response && !response['error'].present?
      self.successed!
    else
      self.failed!
      message = response['error']['message']
    end

    message
  end


  private

  def greater_than_current_time
    if self.end_date <= Time.zone.now
      errors.add(:end_date, 'は将来の日付にしてください')
    end
  end

  def action_url_valid?
    if ['CALL', 'N0_ACTION'].exclude?(self.action_type) && !self.coupon?
      url = URI.parse(self.action_url) rescue false
      errors.add(:action_url, :invalid) unless url.kind_of?(URI::HTTP) || url.kind_of?(URI::HTTPS)
    end
  end

  def redeem_online_url_valid?
    if self.redeem_online_url.present? && self.coupon?
      url = URI.parse(self.redeem_online_url) rescue false
      errors.add(:redeem_online_url, :invalid) unless url.kind_of?(URI::HTTP) || url.kind_of?(URI::HTTPS)
    end
  end
end
