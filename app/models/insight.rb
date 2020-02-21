# == Schema Information
#
# Table name: insights
#
#  id           :bigint           not null, primary key
#  data_type    :integer          not null
#  is_completed :boolean          default(FALSE)
#  month_in     :string(255)      not null
#  value        :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  business_id  :bigint           not null
#
# Indexes
#
#  index_insights_on_business_id  (business_id)
#
# Foreign Keys
#
#  fk_rails_...  (business_id => businesses.id)
#

class Insight < ApplicationRecord
  enum data_type: {
    queries_direct: 1, 
    queries_indirect: 2,
    queries_chain: 3,
    view_search: 4,
    view_maps: 5,
    action_website: 6,
    action_driving_direction: 7,
    action_phone: 8,
    photo_views_merchant: 9,
    photo_views_customer: 10
  }

  belongs_to :business
end
