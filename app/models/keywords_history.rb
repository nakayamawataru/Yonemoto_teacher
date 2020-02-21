# == Schema Information
#
# Table name: keywords_histories
#
#  id          :bigint           not null, primary key
#  content     :string(255)
#  count       :integer          default(0)
#  date        :date
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  business_id :integer
#

class KeywordsHistory < ApplicationRecord
  belongs_to :business

  def self.count_keyword(delay = 0)
    return # Old script - dont use
    today = Date.today - delay.days

    if today == today.beginning_of_month
      Business.update_all(keyword_count: 0)
      User.all.each do |user|
        user.pre_keyword_count = user.keyword_count
        user.keyword_count = 0
        user.save
      end
    end
    Business.active.each do |business|
      keywords = business.keywords
      count    = keywords.count
      next if count.zero?
      business.keywords_histories.create(date: today, count: count, content: keywords.pluck(:value).join(','))
      business.update_columns(keyword_count: business.keyword_count + count )
      if user = business.owner
        user.update_columns(keyword_count: user.keyword_count + count )
      end
      if user = business.user
        user.update_columns(keyword_count: user.keyword_count + count )
        if user = user.agent
          user.update_columns(keyword_count: user.keyword_count + count )
        end
      end
    end
  end

  def self.update_pre_keyword_count
    today = Date.today
    return unless today == today.beginning_of_month

    Business.update_all(keyword_count: 0)
    User.all.each do |user|
      user.pre_keyword_count = user.keyword_count
      user.keyword_count = 0
      user.save
    end
  end

  def self.count_keyword_from_meo_history(delay = 0)
    today = Date.today - delay.days

    business_keyword_counts = MeoHistory.where(date: today.beginning_of_month..today).group(:business_id).count
    # Do not directly update keyword_count to reduce keyword_count = 0 display error
    # Use temp_keyword_count instead while calculating
    User.update_all(temp_keyword_count: 0)
    business_keyword_counts.each do |business_id, keyword_count|
      business = Business.find_by(id: business_id)
      next unless business

      # Update keywords_histories
      keywords = business.keywords
      count    = keywords.count
      keywords_history = business.keywords_histories.find_or_initialize_by(date: today)
      keywords_history.count = count
      keywords_history.content = keywords.pluck(:value).join(',')
      keywords_history.save

      # Update keyword count
      business.update_columns(keyword_count: keyword_count)
      if user = business.owner
        user.update_columns(temp_keyword_count: user.temp_keyword_count + keyword_count)
      end
      if user = business.user
        user.update_columns(temp_keyword_count: user.temp_keyword_count + keyword_count)
        if user = user.agent
          user.update_columns(temp_keyword_count: user.temp_keyword_count + keyword_count)
        end
      end
    end
    # Update from temp_keyword_count into keyword_count
    User.all.each do |user|
      user.update(keyword_count: [user.keyword_count, user.temp_keyword_count].max)
    end
  end
end
