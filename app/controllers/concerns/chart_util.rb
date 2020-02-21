module ChartUtil
  def get_date_labels
    return [] if params[:month].blank? && params[:day_number].blank?
    if params[:month].present?
      cal_labels_by_month
    else
      cal_labels_by_days
    end
  end

  def cal_labels_by_month
    month = params[:month]
    date_array = (1..month.to_date.end_of_month.day).to_a
    date_array << month.to_date.end_of_month.day if date_array.last != month.to_date.end_of_month.day
    date_array.reduce(Array.new){ |a, e| a << (month + "/#{e}").to_date.strftime('%Y/%m/%d')}
  end

  def cal_labels_by_days
    params[:day_number].to_i.days.ago.to_date.upto(Date.today).reduce(Array.new){ |a, e| a << e.strftime('%Y/%m/%d')}
  end

  def load_data_meo(labels)
    return [] if @business.blank?
    memos_data = {
      label: 'メモ',
      data_type: 'memo',
      data: cal_data_memo(labels),
      icons: ["\uf08d"],
      title_memo: cal_data_memo(labels, 'title_memo'),
      datalabels: {
        display: true
      },
      borderColor: 'black',
      showLine: false
    }
    index = 0
    data = @business.keywords.reduce(Array.new) do |arr, keyword|
      i = index % Keyword::COLORS.count
      index+= 1
      arr << {
        label: keyword.value,
        data_type: 'rank',
        data: cal_data_for(keyword, labels),
        borderColor: Keyword::COLORS[i],
        datalabels: {
          display: false
        }
      }
    end
    data << memos_data
  end

  def cal_data_for(keyword, labels)
    ranks = keyword.get_ranking_arr_by(params)
    labels.reduce(Array.new) do |a, e|
      a << ranks.select{|item| item.first.strftime('%Y/%m/%d') == e}.first.try(:second)
    end
  end

  def cal_data_memo(labels, type = 'data')
    date = @business.memos.accessible_by(current_ability).pluck(:date).uniq
    date.map! { |date| date.strftime('%Y/%m/%d') }
    labels.map do |l|
      if type == 'data'
        date.include?(l) ? 0 : nil
      else
        @business.memos.accessible_by(current_ability).by_date(l).pluck(:title).map { |t| "  " + t.truncate(50) }
      end
    end
  end

  # Benchmark Business
  def load_data_meo_benchmark_business(benchmark_business, labels)
    return [] if @business.blank? || benchmark_business.blank?
    index = 0
    @business.keywords.reduce(Array.new) do |arr, keyword|
      i = index % Keyword::COLORS.count
      index+= 1
      arr << {
        label: keyword.value,
        data: cal_data_benchmark_business(benchmark_business, keyword, labels),
        borderColor: Keyword::COLORS[i],
      }
    end
  end

  def cal_data_benchmark_business(benchmark_business, keyword, labels)
    ranks = keyword.get_ranking_benchmark_business(benchmark_business, params)
    labels.reduce(Array.new) do |a, e|
      a << ranks.select{|item| item.first.strftime('%Y/%m/%d') == e}.first.try(:second)
    end
  end
end
