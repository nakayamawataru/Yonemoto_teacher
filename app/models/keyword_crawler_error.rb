# == Schema Information
#
# Table name: keyword_crawler_errors
#
#  id          :bigint           not null, primary key
#  date        :datetime
#  images      :text(65535)
#  times       :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  business_id :integer
#  keyword_id  :integer
#

class KeywordCrawlerError < ApplicationRecord
  serialize :images, Array

  belongs_to :business
  belongs_to :keyword

  class << self
    def times_keyword_error_last(business, keyword, date)
      result = where(business: business, keyword: keyword, date: date).last
      result ? result.times : 0
    end
  end
end
