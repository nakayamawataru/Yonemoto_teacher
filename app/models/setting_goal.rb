# == Schema Information
#
# Table name: setting_goals
#
#  id            :bigint           not null, primary key
#  holiday       :string(255)
#  review_in_day :integer          default(0), not null
#  sms_in_day    :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :bigint           not null
#
# Indexes
#
#  index_setting_goals_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

class SettingGoal < ApplicationRecord
  DAYNAMES = ['日', '月', '火', '水', '木', '金', '土']

  belongs_to :user

  serialize :holiday, Array
end
