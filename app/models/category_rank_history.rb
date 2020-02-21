# == Schema Information
#
# Table name: category_rank_histories
#
#  id         :bigint           not null, primary key
#  date       :date
#  gcid       :string(255)
#  rank       :float(24)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class CategoryRankHistory < ApplicationRecord
end
