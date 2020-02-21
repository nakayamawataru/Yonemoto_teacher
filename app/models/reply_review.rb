# == Schema Information
#
# Table name: reply_reviews
#
#  id          :bigint           not null, primary key
#  auto_reply  :boolean          default(FALSE)
#  content     :text(65535)
#  type_review :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  business_id :integer
#

class ReplyReview < ApplicationRecord
  belongs_to :business

  enum type_review: { less_two_stars: 1, greater_three_stars: 2,
    less_two_stars_no_comment: 3, greater_three_stars_no_comment: 4 }

  def self.type_review_to_text(type_rv)
    case type_rv
    when 'less_two_stars'
      '星２以下の返信文'
    when 'greater_three_stars'
      '星３以上への返信文'
    when 'less_two_stars_no_comment'
      '星２以下の返信文'
    when 'greater_three_stars_no_comment'
      '星３以上への返信文'
    end
  end
end
