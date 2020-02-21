# == Schema Information
#
# Table name: scraping_history_details
#
#  id                  :bigint           not null, primary key
#  scraping_history_id :integer
#  business_id         :integer
#  keyword_id          :integer
#  keyword_value       :string(255)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class ScrapingHistoryDetail < ApplicationRecord
end
