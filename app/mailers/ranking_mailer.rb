class RankingMailer < ApplicationMailer
  def fetch_ranking_error_notify(keyword, json_error)
    return unless Rails.env.production?
    @keyword = keyword
    @json_error = json_error
    email = filter_emails('awahaseg@gmail.com')

    mail(to: email, subject: "MEOチェキ | GMB取得エラー：PlaceAPIエラー")
  end

  def high_ranking_notify(business)
    @business = business
    @keywords_in_top_rank = business.meo_histories.where("rank <= ?", Settings.meo_history.rank_in_top)
    emails = notify_email_from_business(business)
    emails = filter_emails(emails)

    mail(to: emails, subject: "初回上位表示案件発生のお知らせ")
  end
end
