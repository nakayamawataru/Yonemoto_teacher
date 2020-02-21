class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('MAILER_SENDER_ADDRESS', 'noreply@ranktoolap.com')
  layout 'mailer'

  protected
  # Skip sending notification email from agent's businesses to admin
  def notify_email_from_business(business)
    return unless business
    user_business = business.user

    if user_business.agent_meo_check?
      User.admin.pluck(:email) << user_business.email
    elsif user_business.admin?
      User.admin.pluck(:email)
    elsif user_business.agent.present?
      if user_business.agent.agent_meo_check?
        User.admin.pluck(:email) << user_business.agent.email
      else
        user_business.agent.email
      end
    else
      user_business.email
    end
  end

  def filter_emails(emails)
    emails = [emails].flatten.compact
    blacklist_emails = SesBlacklistEmail.where(email: emails).pluck(:email)
    emails - blacklist_emails
  end
end
