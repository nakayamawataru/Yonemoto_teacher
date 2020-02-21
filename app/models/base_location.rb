# == Schema Information
#
# Table name: base_locations
#
#  id                   :bigint           not null, primary key
#  base_address         :string(255)      not null
#  base_address_english :string(255)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#

class BaseLocation < ApplicationRecord
  def self.exist_base_location? location 
    where('base_address = ? or base_address_english = ? ',
      location, location).count.positive?
  end
end
