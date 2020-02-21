# == Schema Information
#
# Table name: total_monthly_fees
#
#  id          :bigint           not null, primary key
#  month_in    :string(255)
#  status      :integer          default("pending")
#  value       :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  business_id :bigint           not null
#
# Indexes
#
#  index_total_monthly_fees_on_business_id  (business_id)
#
# Foreign Keys
#
#  fk_rails_...  (business_id => businesses.id)
#

class TotalMonthlyFee < ApplicationRecord
  belongs_to :business

  enum status: { pending: 0, success: 1, failed: 2, non_paycard: 3 }
  scope :last_month_data, -> { where(month_in: (Date.current - 1.months).strftime('%Y-%m')) }

  DEFAULT_UPDATABLE_ATTRIBUTES = (%i[ value month_in status ]).flatten!
end
