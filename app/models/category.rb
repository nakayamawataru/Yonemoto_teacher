# == Schema Information
#
# Table name: categories
#
#  id         :bigint           not null, primary key
#  gcid       :string(255)
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Category < ApplicationRecord
  has_many :category_business, dependent: :destroy
  has_many :businesses, through: :category_business
end
