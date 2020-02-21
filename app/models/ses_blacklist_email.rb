# == Schema Information
#
# Table name: ses_blacklist_emails
#
#  id         :bigint           not null, primary key
#  added_at   :datetime
#  email      :string(255)
#  email_type :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class SesBlacklistEmail < ApplicationRecord
  before_save :set_added_at, on: :create

  enum email_type: { Bounce: 1, Complaint: 2 }

  private

  def set_added_at
    self.added_at = Time.zone.now
  end
end
