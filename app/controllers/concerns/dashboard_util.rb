module DashboardUtil
  NUM_AGO = 7

  def get_date_labels
    @array_labels = (0..NUM_AGO).to_a.reverse
    case @graph_by
    when 'week'
      cal_labels_by_week
    when 'day'
      cal_labels_by_day
    when 'month'
      cal_labels_by_month
    end
  end

  def get_goal_data
    array_labels = (0..NUM_AGO).to_a.reverse
    sms_goal = []
    review_goal = []
    case @graph_by
    when 'day'
      array_labels.each do
        sms_goal << current_user.setting_goal.try(:sms_in_day).to_i
        review_goal << current_user.setting_goal.try(:review_in_day).to_i
      end
    when 'week'
      array_labels.each do
        sms_goal << current_user.setting_goal.try(:sms_in_day).to_i * 7
        review_goal << current_user.setting_goal.try(:review_in_day).to_i * 7
      end
    when 'month'
      array_labels.each do |n|
        days_in_month = n.months.ago.end_of_month.day
        sms_goal << current_user.setting_goal.try(:sms_in_day).to_i * days_in_month
        review_goal << current_user.setting_goal.try(:review_in_day).to_i * days_in_month
      end
    end
    [sms_goal, review_goal]
  end

  def load_message_data(labels)
    messages = messages_grouped
    labels.reduce(Array.new) do |a, e|
      a << messages.select{|item| item  == e}.first.try(:second).try(:size).to_i
    end
  end

  def load_review_data(labels)
    reviews = reviews_grouped
    labels.reduce(Array.new) do |a, e|
      a << reviews.select{|item| item  == e}.first.try(:second).try(:size).to_i
    end
  end

  private

  def messages_grouped
    case @graph_by
    when 'week'
      @messages.where(created_at: (NUM_AGO.weeks.ago.beginning_of_week..Time.zone.now)).group_by(&:week)
    when 'day'
      @messages.where(created_at: (NUM_AGO.days.ago.beginning_of_day..Time.zone.now)).group_by(&:day)
    when 'month'
      @messages.where(created_at: (NUM_AGO.months.ago.beginning_of_month..Time.zone.now)).group_by(&:month)
    end
  end

  def reviews_grouped
    reviews = Review.where(business_id: @business_ids)
    case @graph_by
    when 'week'
      reviews.where(create_time: (NUM_AGO.weeks.ago.beginning_of_week..Time.zone.now)).group_by(&:week)
    when 'day'
      reviews.where(create_time: (NUM_AGO.days.ago.beginning_of_day..Time.zone.now)).group_by(&:day)
    when 'month'
      reviews.where(create_time: (NUM_AGO.months.ago.beginning_of_month..Time.zone.now)).group_by(&:month)
    end
  end

  def cal_labels_by_week
    @array_labels.reduce(Array.new) { |a, e| a << e.weeks.ago.beginning_of_week.strftime("%m/%d〜") }
  end

  def cal_labels_by_day
    @array_labels.reduce(Array.new) { |a, e| a << e.days.ago.strftime("%m/%d〜") }
  end

  def cal_labels_by_month
    @array_labels.reduce(Array.new) { |a, e| a << e.months.ago.beginning_of_month.strftime("%m/%d〜") }
  end
end
