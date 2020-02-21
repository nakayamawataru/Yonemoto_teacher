# == Schema Information
#
# Table name: coupon_sms_reviews
#
#  id            :bigint           not null, primary key
#  slug          :string(191)      not null
#  used_num      :integer          default(0)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  coupon_id     :bigint           not null
#  sms_review_id :bigint
#
# Indexes
#
#  index_coupon_sms_reviews_on_coupon_id      (coupon_id)
#  index_coupon_sms_reviews_on_slug           (slug)
#  index_coupon_sms_reviews_on_sms_review_id  (sms_review_id)
#
# Foreign Keys
#
#  fk_rails_...  (coupon_id => coupons.id)
#  fk_rails_...  (sms_review_id => sms_reviews.id)
#

class CouponSmsReview < ApplicationRecord
  belongs_to :coupon
  belongs_to :sms_review, optional: true

  def self.generate_slug
    loop do
      random_slug = SecureRandom.alphanumeric(Settings.sms_review.slug_lengh)
      break random_slug unless exists?(slug: random_slug)
    end
  end

  def consume_coupon
    return unless self.coupon.active?
    self.lock!
    self.increment! :used_num
  end
end
