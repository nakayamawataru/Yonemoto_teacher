# == Schema Information
#
# Table name: qa_reviews
#
#  id          :bigint           not null, primary key
#  content     :text(65535)
#  qa_type     :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  business_id :bigint           not null
#

class QaReview < ApplicationRecord
  belongs_to :business

  REVIEW_PATTERN_ALL = 1
  REVIEW_PATTERN_GOOGLE_FIRST = 2

  QUESTION_1 = 'Q1'
  QUESTION_2 = 'Q2'
  ANSWER_1 = 'A1' # = Question 1 return yes + Question 2 return yes
  ANSWER_2 = 'A2' # = Question 1 return yes + Question 2 return no
  ANSWER_3 = 'A3' # = Question 1 return no + Question 2 return yes
  ANSWER_4 = 'A4' # = Question 1 return no + Question 2 return no
end
