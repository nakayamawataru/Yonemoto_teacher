# == Schema Information
#
# Table name: meo_benchmark_business_histories
#
#  id                    :bigint           not null, primary key
#  date                  :date             not null
#  rank                  :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  benchmark_business_id :bigint           not null
#  keyword_id            :bigint           not null
#
# Indexes
#
#  index_meo_benchmark_business_histories_on_benchmark_business_id  (benchmark_business_id)
#  index_meo_benchmark_business_histories_on_keyword_id             (keyword_id)
#
# Foreign Keys
#
#  fk_rails_...  (benchmark_business_id => benchmark_businesses.id)
#  fk_rails_...  (keyword_id => keywords.id)
#

class MeoBenchmarkBusinessHistory < ApplicationRecord
  belongs_to :benchmark_business
  belongs_to :keyword
end
