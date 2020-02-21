# == Schema Information
#
# Table name: staffs
#
#  id         :bigint           not null, primary key
#  display    :boolean          default(FALSE)
#  staffname  :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_staffs_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

class Staff < ApplicationRecord
  DEFAULT_UPDATABLE_ATTRIBUTES = %i[user_id staffname image display]

  belongs_to :user
  has_many :messages, dependent: :destroy

  has_one_attached :image

  scope :is_display, -> { where(display: true) }
end
