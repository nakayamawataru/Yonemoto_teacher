# == Schema Information
#
# Table name: contacts
#
#  id         :bigint           not null, primary key
#  email      :string(255)
#  content    :string(255)
#  type       :integer
#  status     :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Contact < ApplicationRecord
end
