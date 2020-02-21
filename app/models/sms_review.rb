# == Schema Information
#
# Table name: sms_reviews
#
#  id           :bigint           not null, primary key
#  phone_number :string(255)
#  username     :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  business_id  :bigint           not null
#  review_id    :integer
#
# Indexes
#
#  index_sms_reviews_on_business_id  (business_id)
#
# Foreign Keys
#
#  fk_rails_...  (business_id => businesses.id)
#

class SmsReview < ApplicationRecord
  has_many :coupon_sms_reviews, dependent: :destroy
  has_many :coupons, through: :coupon_sms_reviews
  belongs_to :business
  belongs_to :review, optional: true

  def coupon_url(slug)
    base_url = ENV['DOMAIN'] + '/cv/'
    slug.present? ? (base_url + slug) : ''
  end

  class << self
    def import_reviews
      # SmsReview.create(Review.all.map { |rv| { username: rv.reviewer, business_id: rv.business_id, review_id: rv.id } })
      Review.all.each do |rv|
        sms_review = SmsReview.find_or_initialize_by(business_id: rv.business_id, review_id: rv.id)
        sms_review.username = rv.reviewer
        sms_review.save
      end
    end
  end
end
