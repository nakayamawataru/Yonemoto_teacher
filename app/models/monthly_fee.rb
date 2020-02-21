# == Schema Information
#
# Table name: monthly_fees
#
#  id          :bigint           not null, primary key
#  month_in    :string(255)
#  value       :integer          default(0)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  business_id :bigint           not null
#
# Indexes
#
#  index_monthly_fees_on_business_id  (business_id)
#
# Foreign Keys
#
#  fk_rails_...  (business_id => businesses.id)
#

class MonthlyFee < ApplicationRecord
  belongs_to :business
end
