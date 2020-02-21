# == Schema Information
#
# Table name: setting_qrs
#
#  id          :bigint           not null, primary key
#  type        :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  business_id :bigint           not null
#
# Indexes
#
#  index_setting_qrs_on_business_id  (business_id)
#
# Foreign Keys
#
#  fk_rails_...  (business_id => businesses.id)
#

class SettingQr < ApplicationRecord
  SUBCLASS = {
    simple: SettingQr::Simple.name,
    normal: SettingQr::Normal.name,
    sms: SettingQr::Sms.name,
    anonymous: SettingQr::Anonymous.name
  }

  has_one_attached :image
  belongs_to :business

  validates :type, presence: true, inclusion: SUBCLASS.values
end
