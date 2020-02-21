class Api::ChartsController < ApplicationController
  def rank_by_date
    return unless current_user

    date = params[:date].to_date
    if params[:next] == 'true'
      date = date.tomorrow
    elsif params[:previous] == 'true'
      date = date.yesterday
    end
    businesses = Business.accessible_by(current_ability)
    business = current_user.owner? ? current_user.owner_business : businesses.find_by(id: params[:business_id])
    return unless business.present?

    data_rankings = MeoHistory.ranking_current_date(date, business)
    rank_abs = data_rankings.count.positive? ? (data_rankings.map{|x| x[:rank_number].to_i}.sum.to_f/data_rankings.count).round(2) : 0
    memos = business.memos.accessible_by(current_ability).where(date: date).map{|m| current_user == m.user ? m.title : "#{m.title} （#{m.user.company}）"}

    render json: {
      data: data_rankings,
      date_check: date.strftime('%d/%m/%Y'),
      text_date: I18n.l(date, format: '%Y年%m月%d日(%A)'),
      rank_abs: rank_abs > 0 ? "平均値:  #{rank_abs}" : '平均値: --- ',
      memos: memos
    }
  end
end
