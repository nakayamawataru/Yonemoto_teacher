# == Schema Information
#
# Table name: keyword_reviews
#
#  id         :bigint           not null, primary key
#  value      :string(255)      not null
#  word_type  :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint
#

class KeywordReview < ApplicationRecord
  DEFAULT_UPDATABLE_ATTRIBUTES = %i[word_type value user_id]

  belongs_to :user, optional: true

  enum word_type: { positive: 1, negative: 0, whitelist: 2 }
end
