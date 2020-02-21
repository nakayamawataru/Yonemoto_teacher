class SesMailer < ApplicationMailer
  def bounce_email_notify(new_emails)
    @new_emails = new_emails
    mail(
      to: filter_emails(["awahaseg@gmail.com"]),
      subject: "MEOチェキ | 新しいバウンスメールのお知らせ"
    )
  end
end
