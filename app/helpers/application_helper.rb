module ApplicationHelper
  def show_errors(object, field_name)
    return unless object.errors.any?

    str = "<ul class='tm-validation-errors'>"
    object.errors.full_messages_for(field_name).uniq.each do |message|
      str += "<li class='tm-validation-error-message'>#{message}</li>"
    end
    str += '</ul>'
    str.html_safe
  end

  def paginate objects, options = {}
    options.reverse_merge!( theme: 'twitter-bootstrap-3', remote: true )

    super( objects, options )
  end

  def months_views_meo_data(business)
    return [] if business.blank?
    first_created_meo = business.meo_histories.order('date ASC').first.try(:date).try(:to_date)
    return [] if first_created_meo.blank?
    (first_created_meo..Date.today).to_a.map do |month|
      [month.strftime('%Y/%m'), month.strftime('%Y年%m月')]
    end.uniq.reverse
  end

  def convert_status(status)
    case status
    when 'active'
      return '対策中'
    when 'stopped'
      return '停止中'
    when 'canceled'
      return '解約済'
    end
  end

  def convert_payment_status(status)
    case status
    when 'pending'
      return '未決済'
    when 'success'
      return '決済完了'
    when 'failed'
      return '決済失敗'
    when 'non_paycard'
      return 'カード未連携'
    end
  end

  def render_stars(value)
    output = ''
    floored = value.floor

    floored.times { output << "<i class='fa fa-star'></i>" }

    if (value - floored) >= 0.5
      output << "<i class='fa fa-star-half'></i>"
    end

    (5 - value).round.times { output << "<i class='fa fa-star-o'></i>" }
    output.html_safe
  end

  def get_status_and_slug(sms_review, coupon)
    data = sms_review.coupon_sms_reviews.find_by coupon: coupon
    if data.present?
      return [(data.used_num > 0 ? 'クーポン使用済' : 'SMS送信済'), data.slug]
    else
      return [nil, nil]
    end
  end

  def convert_message_status(status)
    output = ''
    case status
    when 'finished'
      output = '<i class="fa fa-envelope"></i>'
    when 'failed'
      output = '<span style="color:red;">送信失敗</span>'
    end
    output.html_safe
  end

  def manager?
    session[:manager_id].present? || current_user.admin? || current_user.is_agent?
  end

  def logo_widget(business)
    business.owner&.logo_url || business.user&.logo_url ||
      business.user&.agent&.logo_url || 'tryhatch.png'
  end

  def url_logo_widget(business)
    if business.owner&.logo_url
      business.owner&.logo_target_url
    elsif business.user&.logo_url
      business.user&.logo_target_url
    elsif business.user&.agent&.logo_url
      business.user&.agent&.logo_target_url
    else
      'https://meo.tryhatch.co.jp'
    end
  end

  def color_widget(business)
    business.owner&.color.presence || business.user&.color.presence ||
      business.user&.agent&.color.presence || '#29B03D'
  end

  def format_date_coupon(date, type='%Y-%m-%d %H:%M')
    date ? date.strftime(type) : ''
  end

  def post_type_as_text(post_type)
    case post_type
    when 'what_news'
      return '最新情報'
    when 'event'
      return 'イベント'
    when 'coupon'
      return 'クーポン（特典）'
    end
  end

  def post_status_as_text(status)
    case status
    when 'successed'
      return '成功'
    when 'failed'
      return '失敗'
    when 'pending'
      return '未投稿'
    end
  end

  def action_type_as_text(action_type)
    case action_type
    when 'BOOK'
      return '予約'
    when 'ORDER'
      return 'オンライン注文'
    when 'SHOP'
      return '購入'
    when 'LEARN_MORE'
      return '詳細'
    when 'SIGN_UP'
      return '登録'
    when 'CALL'
      return '今すぐ電話'
    end
  end

  def option_action_types
    [
      ['なし', 'N0_ACTION'],
      ['予約', 'BOOK'],
      ['オンライン注文', 'ORDER'],
      ['購入', 'SHOP'],
      ['詳細', 'LEARN_MORE'],
      ['登録', 'SIGN_UP'],
      ['今すぐ電話', 'CALL'],
    ]
  end

  def parse_color
    if current_user && current_user.owner?
      main_color = current_user.header_color.presence

      if !main_color && current_user.owner_business
        user = current_user.owner_business.user
        main_color = user&.header_color.presence || user.agent&.header_color.presence
      end
    else
      main_color = current_user&.header_color.presence || current_user&.agent&.header_color.presence
    end

    main_color ||= '#02A5AD'

    {
      main_color: main_color,
      header_color: main_color.paint.darken(5),
      hover_color: main_color.paint.darken(6)
    }
  end

  def url_header_logo
    if current_user && current_user.owner?
      header_logo_url = current_user&.header_logo_url

      if !header_logo_url && current_user.owner_business
        user = current_user.owner_business.user
        header_logo_url = user&.header_logo_url || user.agent&.header_logo_url
      end
    else
      header_logo_url = current_user&.header_logo_url || current_user&.agent&.header_logo_url
    end
    header_logo_url
  end

  def report_rank_as_text(rank)
    [0, 21].include?(rank.to_i) ? '圏外' : rank.to_s + ' 位'
  end

  def report_class_rank(rank)
    if (1..3).to_a.include? rank
      'report-top-rank'
    elsif(4..20).to_a.include? rank
      'report-normal-rank'
    else
      'report-out-rank'
    end
  end

  def review_url_with_type(business, business_type)
    case business_type
    when 'google'
      business.try(:review_url).to_s
    when 'yahoo'
      business.try(:yahoo_place_url).to_s
    when 'ekiten'
      business.try(:ekiten_url).to_s
    when 'facebook'
      business.try(:facebook_url).to_s
    when 'instagram'
      business.try(:instagram_url).to_s
    when 'hotpepper'
      business.try(:hotpepper_url).to_s
    when 'e-park'
      business.try(:e_park_url).to_s
    else
      business.try(:default_review_url).to_s
    end
  end

  def content_qa_review(business, qa_type)
    business.qa_reviews.find_by(qa_type: qa_type).try(:content).to_s
  end

  def button_business_review(bid, business_type, text_type, class_icon, url_service)
    return unless url_service.present?

    link_to(questions_r_path(id: bid, business_type: business_type), class: 'btn btn-primary btn-yes') do
      (content_tag(:i, '', class: class_icon) + ' ' + text_type).html_safe
    end
  end
end
