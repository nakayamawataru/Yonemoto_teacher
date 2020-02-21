# == Schema Information
#
# Table name: benchmark_businesses
#
#  id          :bigint           not null, primary key
#  name        :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  business_id :bigint           not null
#
# Indexes
#
#  index_benchmark_businesses_on_business_id  (business_id)
#
# Foreign Keys
#
#  fk_rails_...  (business_id => businesses.id)
#

class BenchmarkBusiness < ApplicationRecord
  belongs_to :business
  has_many :meo_benchmark_business_histories, dependent: :delete_all
end
