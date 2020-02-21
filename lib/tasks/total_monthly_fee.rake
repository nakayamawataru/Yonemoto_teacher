namespace :total_monthly_fee do
  desc "Total monthly fee"
  task execute: :environment do
    last_month = Date.current - 1.months
    days = (last_month.beginning_of_month..last_month.end_of_month).map{|d| d.strftime('%Y/%m/%d')}

    Business.active.each do |business|
      total_day_rank_top = business.day_top_rank_in_month(days, Business::COUNT_RANK)
      total_cost =
        if business.performance_month_fee.to_i.positive?
          business.performance_month_fee
        else
          total_day_rank_top * business.performance_fee.to_i
        end

      business.total_monthly_fees.create(
        month_in: last_month.strftime('%Y-%m'),
        value: total_cost
      )
    end
  end
end
