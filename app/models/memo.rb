# == Schema Information
#
# Table name: memos
#
#  id          :bigint           not null, primary key
#  date        :date
#  title       :text(65535)
#  business_id :bigint           not null
#  user_id     :bigint
#
# Indexes
#
#  index_memos_on_business_id  (business_id)
#  index_memos_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (business_id => businesses.id)
#

class Memo <  ApplicationRecord
  belongs_to :business
  belongs_to :user

  scope :by_date,-> (date) { where(date: date) }

  def self.search(params, current_ability)
    return [] if params[:business_id].blank?

    res = accessible_by(current_ability)
    res = res.where(business_id: params[:business_id])
    res.order(date: :desc).group_by(&:date).to_a
  end
end
