# == Schema Information
#
# Table name: review_requests
#
#  id               :bigint           not null, primary key
#  business_id      :integer
#  user_id          :integer
#  reviewer         :string(255)
#  phone_number     :string(255)
#  request_datetime :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class ReviewRequest < ApplicationRecord
end
