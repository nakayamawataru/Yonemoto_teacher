class MessageMailer < ApplicationMailer
  def send_message(to, content)
    @content = content

    mail(to: to, subject: "口コミのご協力をお願い致します")
  end

  def email_error(message)
    @message
    @business = message.business
    email = filter_emails(@business.user.email)
    email_bcc = filter_emails('zaqopqqq@gmail.com')

    mail(to: email, bcc: email_bcc, subject: "Emailで送信失敗")
  end

  def feedback(business_id, content)
    @content = content
    @business = Business.find_by(id: business_id)
    email = filter_emails(@business&.owner&.email)

    mail(to: email, subject: "おすすめできないの連絡")
  end
end
