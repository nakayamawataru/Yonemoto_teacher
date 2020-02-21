module CalendarUtil
  def load_events(rank = nil, current_user)
    return [] if @business.blank?
    return [] if @month.blank?
    month_as_date = @month.to_date
    with_rank = rank.present? ? rank : @within_rank
    index = 0
    @business.keywords.order(:id).reduce(Array.new) do |events, keyword|
      i = index % Keyword::COLORS.count
      index+= 1
      date_range = (month_as_date.beginning_of_month..month_as_date.end_of_month)
      items_event = keyword.meo_histories.where(business: @business)
                                         .where(date: date_range)
      if with_rank != 'all'
        items_event = items_event.where('rank <= ?', with_rank)
      end
      events << items_event.map do |item|
        {
          id: keyword.id,
          title: "#{keyword.value}  #{item.rank_as_text}",
          start: item.date.strftime('%Y-%m-%d'),
          end: item.date.strftime('%Y-%m-%d'),
          color: color_keyword(i, item.rank, current_user),
        }
      end
    end.flatten.compact
  end

  def csv_data
    attributes = %w(日付 施設名 検索キーワード 順位 検索地域)
    CSV.generate(headers: true) do |csv|
      csv << attributes
      load_rows.each { |row| csv << row.values }
    end
  end

  def load_rows
    month_as_date = @month.to_date
    @business.keywords.reduce(Array.new) do |meo_arrays, keyword|
      date_range = (month_as_date.beginning_of_month..month_as_date.end_of_month)
      meo_arrays << keyword.meo_histories.where(business: @business)
                                         .where(date: date_range)
                                         .where('rank <= ?', @within_rank == 'all' ? 21 : @within_rank)
                                         .map do |item|
        {
          date: item.date.strftime('%Y-%m-%d'),
          business_name: @business.name,
          keyword: keyword.value,
          rank: item.rank,
          base_address: @business.base_address
        }
      end
    end.flatten.compact
  end

  def color_keyword(index, rank, current_user)
    return Keyword::COLORS[index] unless @business.user.agent_setting.try(:super_regional_calendar?)

    color =
      if (1..3).to_a.include? rank.to_i
        '#0077CC'
      elsif(4..19).to_a.include? rank.to_i
        '#CCBB01'
      elsif rank.to_i == 20
        '#CC0011'
      else
        '#808080'
      end

    return color
  end
end
