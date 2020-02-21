# == Schema Information
#
# Table name: scraping_histories
#
#  id                :bigint           not null, primary key
#  executed_datetime :datetime
#  status            :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class ScrapingHistory < ApplicationRecord
end
