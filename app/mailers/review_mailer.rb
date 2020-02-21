class ReviewMailer < ApplicationMailer
  def bad_rating_notify(business_id, content, reviewer, create_time)
    @business = Business.find_by id: business_id
    return unless @business.present?
    @content = content
    @reviewer = reviewer
    @create_time = create_time

    # 代理店
    agent_user = @business.user.is_agent? ? @business.user : @business.user.agent
    emails = ['review.hoshikakutokun@gmail.com'] << agent_user.try!(:email)

    # 店舗ユーザー
    if @business.user.owner?
      emails << @business.user.email
    end
    emails = filter_emails(emails)

    mail(
      to: emails,
      subject: "星２以下の口コミが投稿されました"
    )
  end

  def bad_comment_notify(business_id, list_words, content, reviewer, create_time)
    @business = Business.find_by id: business_id
    return unless @business.present?
    @content = content
    @reviewer = reviewer
    @create_time = create_time
    @words = list_words.reduce(Array.new){ |a, e| a << "「#{e}」" }.join(", ")
    title = "ネガティブワード（#{@words}）が口コミ投稿されました"

    emails = ["review.hoshikakutokun@gmail.com"]
    # 代理店
    agent_user = @business.user.is_agent? ? @business.user : @business.user.agent
    if agent_user && !agent_user.restricted
      emails << agent_user.email
    end

    # 店舗ユーザー
    if @business.user.owner? && !@business.user.restricted
      emails << @business.user.email
    end
    if @business.owner && !@business.owner.restricted
      emails << @business.owner.email
    end
    emails = filter_emails(emails)
    bcc_emails = filter_emails(["awahaseg@gmail.com"])

    mail(
      to: emails,
      bcc: bcc_emails,
      subject: title
    )
  end
end
