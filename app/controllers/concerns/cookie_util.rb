module CookieUtil
  def set_notification_cookie
    return unless current_user

    if current_user.user? && !current_user.nested_owner_present?
      notifications = Notification.available.by_user_role(Notification::USER_ROLES[:user_without_agent])
    else
      notifications = Notification.available.by_user_role(Notification::USER_ROLES[current_user.role.to_sym])
    end
    return unless notifications.any?

    notifications.each do |notification|
      key = "notification_news_#{notification.id}"
      @notification_cookie = cookies.signed[key].presence || []
      next if @notification_cookie.include? current_user.id

      cookies.signed[key] = if cookies.signed[key]
        cookies.signed[key].push(current_user.id)
      else
        {value: [current_user.id], expires: notification.end_at}
      end
      @notification = notification
      break
    end
  end
end
