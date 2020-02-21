# == Schema Information
#
# Table name: coupons
#
#  id          :bigint           not null, primary key
#  description :text(65535)
#  expire_at   :datetime
#  limit_num   :integer          not null
#  message     :text(65535)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  business_id :bigint           not null
#
# Indexes
#
#  index_coupons_on_business_id  (business_id)
#
# Foreign Keys
#
#  fk_rails_...  (business_id => businesses.id)
#

class Coupon < ApplicationRecord
  DEFAULT_UPDATABLE_ATTRIBUTES = %i[business_id limit_num expire_at description image message]

  has_many :coupon_sms_reviews, dependent: :destroy
  has_many :sms_reviews, through: :coupon_sms_reviews
  belongs_to :business

  has_one_attached :image

  validates :limit_num, presence: true

  def active?
    self.expire_at.blank? || (self.expire_at.present? && self.expire_at > Time.zone.now)
  end

  def save_preview
    preview = coupon_sms_reviews.find_or_initialize_by(sms_review: nil)
    preview.slug = CouponSmsReview.generate_slug if preview.slug.blank?
    preview.save ? preview.slug : ''
  end

  def send_sms params
    send_failed = []
    base_url = ENV['DOMAIN'] + '/cv/'
    SmsReview.where(id: params[:sms_review_ids]).each do |sms_review|
      begin
        slug = CouponSmsReview.generate_slug
        text_message = message.present? ? message.to_s : 'クーポンはこちらから'
        TwilioTextMessenger.new(sms_review.phone_number, (text_message + "\r\n" + base_url + slug)).call
        self.coupon_sms_reviews.create sms_review: sms_review, slug: slug
      rescue
        send_failed << sms_review.phone_number
        next
      end
    end
    send_failed
  end
end
