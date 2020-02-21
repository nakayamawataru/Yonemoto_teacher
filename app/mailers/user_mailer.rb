class UserMailer < ApplicationMailer
  def register_demo_user(user)
    @user = user
    email =
      if Rails.env.production?
        'sales@tryhatch.co.jp'
      else
        'awahaseg@gmail.com'
      end

    mail(
      to: filter_emails(email),
      subject: "MEOチェキ | デモユーザーが登録されました#{user.company.to_s + ' ' + user.name.to_s}"
    )
  end
end
