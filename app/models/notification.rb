# == Schema Information
#
# Table name: notifications
#
#  id         :bigint           not null, primary key
#  button_url :string(255)      not null
#  content    :text(65535)      not null
#  end_at     :datetime         not null
#  start_at   :datetime         not null
#  user_role  :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Notification < ApplicationRecord
  serialize :user_role

  DEFAULT_UPDATABLE_ATTRIBUTES = [:content, :start_at, :end_at, :button_url, user_role: []]
  USER_ROLES = {
    admin: 1,
    agent: 2,
    agent_meo_check: 3,
    owner: 4,
    user: 5,
    user_without_agent: 6,
    demo_user: 7
  }

  validates :content, :start_at, :end_at, :button_url, presence: true
  validates :end_at, end_at_datetime: true

  scope :id_desc, -> { order(id: :desc) }
  scope :available, -> (time = Time.zone.now) { where('start_at <= ? AND end_at >= ?', time, time).order(start_at: :desc) }
  scope :by_user_role, -> (role) { where("user_role like ?", "%'#{role}'%") }

  def delivery_time
    "#{start_at.strftime('%Y/%m/%d %H:%M')} - #{end_at.strftime('%Y/%m/%d %H:%M')}"
  end
end
