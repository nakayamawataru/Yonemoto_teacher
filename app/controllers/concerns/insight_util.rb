require 'business_time'

module InsightUtil
  def load_insight_data
    return if @business.blank?
    @range_months_title = (day_insight_data - 2.months).strftime("%Y年%m月") + '～' + day_insight_data.strftime("%Y年%m月")
    @range_year_title = (day_insight_data - 11.months).strftime("%Y年%m月") + '～' + day_insight_data.strftime("%Y年%m月")
    load_data_insight_current_month
    load_data_insight_range_months(Settings.insights.range_months)
    load_data_insight_range_months(Settings.insights.range_year)
    @display_day = display_day
  end

  # Data for current month
  def load_data_insight_current_month
    @current_month_title = day_insight_data.strftime("%Y年%m月")
    all_data_in_current_month
    search_method_data_current_month
    display_location_data_current_month
    action_data_current_month
    photo_views_data_current_month
  end

  def all_data_in_current_month
    @month_in = day_insight_data.strftime('%Y-%m')
    @insight_data = @business.insights.where(month_in: @month_in).pluck(:data_type, :value)
  end

  def search_method_data_current_month
    queries_direct = @insight_data.select{|item| item.first == 'queries_direct' }.first.try(:last).to_i
    queries_indirect = @insight_data.select{|item| item.first == 'queries_indirect' }.first.try(:last).to_i
    queries_chain = @insight_data.select{|item| item.first == 'queries_chain' }.first.try(:last).to_i
    gon.push({
      search_method_data_current_month: [ queries_direct, queries_indirect - queries_chain, queries_chain ]
    })
  end

  def display_location_data_current_month
    view_search = @insight_data.select{|item| item.first == 'view_search' }.first.try(:last).to_i
    view_maps = @insight_data.select{|item| item.first == 'view_maps' }.first.try(:last).to_i
    gon.push({
      display_location_data_current_month: [ view_search, view_maps ]
    })
  end

  def action_data_current_month
    action_website = @insight_data.select{|item| item.first == 'action_website' }.first.try(:last).to_i
    action_driving_direction = @insight_data.select{|item| item.first == 'action_driving_direction' }.first.try(:last).to_i
    action_phone = @insight_data.select{|item| item.first == 'action_phone' }.first.try(:last).to_i
    gon.push({
      action_data_current_month: [ action_website, action_driving_direction, action_phone ]
    })
  end

  def photo_views_data_current_month
    photo_views_merchant = @insight_data.select{|item| item.first == 'photo_views_merchant' }.first.try(:last).to_i
    photo_views_customer = @insight_data.select{|item| item.first == 'photo_views_customer' }.first.try(:last).to_i
    gon.push({
      photo_views_data_current_month: [ photo_views_merchant, photo_views_customer ]
    })
  end

  # Data for months compare with months last year
  def load_data_insight_range_months(num_of_month)
    type = num_of_month == Settings.insights.range_year ? 'year' : 'month'
    range_months = (0..(num_of_month - 1)).to_a.reverse
    month_labels = range_months.reduce([]){ |a, e| a << (day_insight_data - e.months).strftime("%m月") }
    gon.push({
      "current_year_data_#{type}" => all_data_in_range_months(range_months),
      "last_year_data_#{type}" => all_data_in_range_months(range_months, true),
      "month_labels_#{type}" => month_labels
    })
  end

  def all_data_in_range_months(range_months, last_year = false)
    data = {
      queries_direct: [],
      queries_indirect: [],
      queries_chain: [],
      view_search: [],
      view_maps: [],
      action_website: [],
      action_driving_direction: [],
      action_phone: [],
      photo_views_merchant: [],
      photo_views_customer: []
    }
    month_ins = []
    range_months.each do |i|
      time = last_year ? (day_insight_data - 12.month - i.months) : (day_insight_data - i.months)
      month_ins << time.strftime('%Y-%m')
    end
    calculate_data(month_ins, data)
    data
  end

  def calculate_data(month_ins, data)
    insight_data = @business.insights.where(month_in: month_ins).pluck(:data_type, :month_in, :value)
    month_ins.each do |month|
      queries_indirect = insight_data.select{|item| item.first == 'queries_indirect' && item.second == month }.first.try(:last).to_i
      queries_chain = insight_data.select{|item| item.first == 'queries_chain' && item.second == month }.first.try(:last).to_i
      data[:queries_direct] << insight_data.select{|item| item.first == 'queries_direct' && item.second == month}.first.try(:last).to_i
      data[:queries_indirect] << queries_indirect - queries_chain
      data[:queries_chain] << queries_chain
      data[:view_search] << insight_data.select{|item| item.first == 'view_search' && item.second == month }.first.try(:last).to_i
      data[:view_maps] << insight_data.select{|item| item.first == 'view_maps' && item.second == month }.first.try(:last).to_i
      data[:action_website] << insight_data.select{|item| item.first == 'action_website' && item.second == month }.first.try(:last).to_i
      data[:action_driving_direction] << insight_data.select{|item| item.first == 'action_driving_direction' && item.second == month }.first.try(:last).to_i
      data[:action_phone] << insight_data.select{|item| item.first == 'action_phone' && item.second == month }.first.try(:last).to_i
      data[:photo_views_merchant] << insight_data.select{|item| item.first == 'photo_views_merchant' && item.second == month }.first.try(:last).to_i
      data[:photo_views_customer] << insight_data.select{|item| item.first == 'photo_views_customer' && item.second == month }.first.try(:last).to_i
    end
  end

  def display_day
    Settings.insights.display_after.days.after(Time.zone.now.beginning_of_month)
  end

  def day_insight_data
    Time.now < display_day ? 2.months.ago : Time.zone.now.last_month
  end
end
