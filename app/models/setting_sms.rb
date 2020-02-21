# == Schema Information
#
# Table name: setting_sms
#
#  id                       :bigint           not null, primary key
#  content                  :text(65535)
#  review_url_email_enabled :boolean          default(FALSE)
#  review_url_enabled       :boolean          default(FALSE)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  business_id              :bigint           not null
#
# Indexes
#
#  index_setting_sms_on_business_id  (business_id)
#
# Foreign Keys
#
#  fk_rails_...  (business_id => businesses.id)
#

class SettingSms < ApplicationRecord
  belongs_to :business
  has_many :sms_patterns, dependent: :delete_all
  has_many :email_patterns, dependent: :delete_all

  before_save :set_default_content, if: Proc.new { self.content.blank? }

  accepts_nested_attributes_for :sms_patterns, allow_destroy: true
  accepts_nested_attributes_for :email_patterns, allow_destroy: true

  validate :sms_patterns_number, :email_patterns_number

  def sms_patterns_number
    patterns = sms_patterns.select{|pattern| !pattern.marked_for_destruction?}
    if patterns.count > 3
      errors.add(:sms_patterns, "は3つ以下にしてください")
    end
  end

  def email_patterns_number
    patterns = email_patterns.select{|pattern| !pattern.marked_for_destruction?}
    if patterns.count > 3
      errors.add(:email_patterns, "は3つ以下にしてください")
    end
  end

  private

  def set_default_content
    self.content = I18n.t('setting_sms.default_content')
  end
end
