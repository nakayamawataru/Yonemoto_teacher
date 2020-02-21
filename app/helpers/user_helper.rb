module UserHelper
  def role_as_text(role)
    case role
    when 'user'
      return 'ユーザー'
    when 'agent'
      return '代理店'
    when 'admin'
      return '管理者'
    when 'owner'
      return '店舗'
    when 'agent_meo_check'
      return 'MEOチェキ'
    when 'demo_user'
      return 'デモ'
    end
  end

  def setting_calendar_as_text(setting)
    case setting
    when 'default_calendar'
      return '通常'
    when 'super_regional_calendar'
      return 'スーパーリジョナル'
    end
  end

  def setting_memo_as_text(setting)
    case setting
    when 'default_memo'
      return '通常'
    when 'super_regional_memo'
      return 'スーパーリジョナル'
    end
  end

  def user_can_views
    manager = User.find_by(id: session[:manager_id] || current_user.id)
    users = manager.admin? ? User.all : manager.users
    users.include?(manager) ? users : [manager] + users
  end

  def convert_gmb_connect_status(status)
    case status
    when 'connecting'
      return 'label-warning'
    when 'connected'
      return 'label-success'
    else
      return 'label-danger'
    end
  end

  def display_restricted(user)
    if user && user.nested_owner.present?
      '口コミ促進'
    else
      '星カクトくん'
    end
  end
end
