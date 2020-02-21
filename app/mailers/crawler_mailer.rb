class CrawlerMailer < ApplicationMailer
  def set_base_location(business)
    return unless Rails.env.production?
    @business = business
    email = filter_emails('awahaseg@gmail.com')

    mail(to: email, subject: "MEOチェキ | GMB取得エラー：住所指定検索無し")
  end

  def warning_crawler_keyword(times)
    return unless Rails.env.production?
    @results = KeywordCrawlerError.where(date: Date.today, times: times)
    email = filter_emails('awahaseg@gmail.com')

    mail(to: email, subject: "MEOチェキ | GMB取得エラー：スクレイピング連続失敗")
  end

  def sms_error(message)
    @message
    @business = message.business
    email = filter_emails(@business.user.email)
    email_bcc = filter_emails('awahaseg@gmail.com')

    mail(to: email, bcc: email_bcc, subject: " MEOチェキ | SMS送信失敗")
  end

  def warning_auto_crawler_rank_keyword(message, backtrace)
    return unless Rails.env.production?
    @message = message
    @backtrace = backtrace
    email = filter_emails('awahaseg@gmail.com')

    mail(to: email, subject: " MEOチェキ | GMB取得エラー")
  end

  def out_rank(meo_history)
    return unless Rails.env.production?
    @meo_history = meo_history
    emails = notify_email_from_business(meo_history&.business)
    emails = filter_emails(emails)

    mail(to: emails, subject: "MEOチェキ | 急降下アラート(#{@meo_history&.business&.name.to_s})")
  end
end
