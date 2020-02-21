# == Schema Information
#
# Table name: meo_histories
#
#  id                     :bigint           not null, primary key
#  base_location          :string(255)
#  base_location_japanese :string(255)
#  capture_image          :string(255)
#  date                   :datetime         not null
#  images                 :text(65535)
#  rank                   :integer          not null
#  type_rank              :integer          default("crawler")
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  business_id            :bigint           not null
#  keyword_id             :bigint           not null
#
# Indexes
#
#  index_meo_histories_date_business_id       (date,business_id)
#  index_meo_histories_date_business_id_rank  (date,business_id,rank)
#  index_meo_histories_on_business_id         (business_id)
#  index_meo_histories_on_keyword_id          (keyword_id)
#  index_meo_histories_on_type_rank           (type_rank)
#
# Foreign Keys
#
#  fk_rails_...  (business_id => businesses.id)
#  fk_rails_...  (keyword_id => keywords.id)
#

class MeoHistory < ApplicationRecord
  serialize :images, Array

  belongs_to :business
  belongs_to :keyword

  enum type_rank: { crawler: 1, upload: 2 }

  def rank_as_text
    rank < Settings.meo_history.out_of_range ? (rank.to_s + '位') : 'ランク外'
  end

  def meo_previous
    MeoHistory.find_by(date: date - 1.day, keyword_id: keyword_id,
      business_id: business_id)
  end

  def in_rank?
    rank > 0 && rank < 21
  end

  def top_rank?
    rank >= 1 && rank <= 3
  end

  class << self
    def base_location_meo(business_chart, date, keyword, rank)
      keyword_chart = Keyword.find_by(business: business_chart, value: keyword)
      base_location = MeoHistory.find_by(business: business_chart, date: date, keyword: keyword_chart, rank: rank)
      base_location.try(:base_location_japanese).to_s
    end

    def ranking_current_date(date, business)
      data = []
      if business.present?
        meo_histories = business.meo_histories.where(date: date).order(keyword_id: :asc)
        meo_histories.each do |meo|
          rank_previous_day =
            meo.meo_previous.try(:rank).to_i == 21 ? 0 : meo.meo_previous.try(:rank).to_i
          current_rank = meo.rank.to_i == 21 ? 0 : meo.rank.to_i
          compare_rank =
            if (rank_previous_day == 0 && current_rank > 0) ||
              (rank_previous_day > 0 && current_rank == 0)
              rank_previous_day - current_rank
            else
              current_rank - rank_previous_day
            end

          item = {
            date: meo.date.strftime('%d-%m-%Y'),
            keyword: meo.keyword.try(:value),
            ranking: meo.rank_as_text,
            rank_number: meo.rank.to_i,
            base_location_japanese: meo.base_location_japanese.to_s,
            compare_rank: compare_rank
          }

          data.push item
        end
      end

      data
    end

    def to_csv
      headers = ['案件名', 'キーワード', '日', '順位', '案件ID', 'キワードID', '順位履歴ID']
      CSV.generate(headers: true) do |csv|
        csv << headers
        all.each do |meo|
          data = [
            meo&.business&.name,
            meo&.keyword&.value,
            meo.date.try(:strftime, '%Y-%m-%d'),
            meo.rank,
            meo.business_id,
            meo.keyword_id,
            meo.id
          ]

          csv << data
        end
      end
    end
  end
end
