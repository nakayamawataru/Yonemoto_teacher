# == Schema Information
#
# Table name: category_businesses
#
#  id            :bigint           not null, primary key
#  category_type :integer          default("addition")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  business_id   :integer
#  category_id   :integer
#

class CategoryBusiness < ApplicationRecord
  belongs_to :business, optional: true
  belongs_to :category, optional: true

  enum category_type: { primary: 1, addition: 2 }
end
