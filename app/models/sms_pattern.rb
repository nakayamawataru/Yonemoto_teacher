# == Schema Information
#
# Table name: sms_patterns
#
#  id             :bigint           not null, primary key
#  content        :text(65535)
#  name           :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  setting_sms_id :integer
#

class SmsPattern < ApplicationRecord
  belongs_to :setting_sms
  has_many :messages, dependent: :delete_all
end
