class PaymentMailer < ApplicationMailer
  def payment_failed(user)
    @user = user
    mail(to: user.try(:email).to_s, subject: "MEOチェキ | 決済エラー")
  end
end
