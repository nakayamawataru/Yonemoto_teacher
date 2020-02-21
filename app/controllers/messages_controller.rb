class MessagesController < BaseController
  include DashboardUtil
  require 'rchardet'

  skip_authorize_resource

  skip_before_action :set_params
  before_action :check_ability!, except: %i[index]
  before_action :load_data, only: %i[index]
  before_action :check_restricted_review, only: %i[create]

  def index
    @businesses = Business.accessible_by(current_ability)
    @business = current_user.owner? ? current_user.owner_business : @businesses.find_by(id: params[:business_id])
    @message = Message.new
    @smses = Message.sms.accessible_by(current_ability).includes(:staff, :business).where(business: @business).order('id DESC').page(params[:sms_page]).per(DEFAULT_PER_PAGE)
    @emails = Message.email.accessible_by(current_ability).includes(:staff, :business).where(business: @business).order('id DESC').page(params[:email_page]).per(DEFAULT_PER_PAGE)

    labels = get_date_labels
    gon.push({
      labels: labels,
      messages_count: load_message_data(labels),
      reviews_count: load_review_data(labels),
      goal_messages_count: get_goal_data[0],
      goal_reviews_count: get_goal_data[1],
    })
    @staffs = Staff.accessible_by(current_ability).is_display
    respond_to do |format|
      format.html
      format.js { render layout: false }
    end
  end

  def create
    @business = Business.accessible_by(current_ability).find_by(id: params[:message][:business_id] || params[:business_id])

    # case: bulk import
    if params[:csv_lists].present?
      return import_bulk
    end

    if current_user.sent_messages.by_month(Time.zone.now).count >= current_user.max_sms_in_month
      @cannot_send = true
    else
      set_params
      set_content(@message, @business)
      @message.sender_id = current_user.id
      @message.save
    end

    respond_to do |format|
      format.js { render layout: false }
    end
  end

  def destroy
    if @message.destroy
      flash[:success] = '削除しました'
    else
      flash[:danger] = '削除できませんでした'
    end
    if @message.email?
      redirect_to messages_path(business_id: @message.business_id, email_import: 'true')
    else
      redirect_to messages_path(business_id: @message.business_id)
    end
  end

  def import
    @business = Business.accessible_by(current_ability).find_by id: params[:business_id]
    @message = Message.new
    @smses = Message.sms.accessible_by(current_ability).includes(:staff, :business).where(business: @business).order('id DESC').page(params[:sms_page]).per(DEFAULT_PER_PAGE)
    @emails = Message.email.accessible_by(current_ability).includes(:staff, :business).where(business: @business).order('id DESC').page(params[:email_page]).per(DEFAULT_PER_PAGE)
    if params[:csv_file].present?
      send("import_#{params[:type]}_lists")
      if @cannot_send
        if params[:type] == 'email'
          return redirect_to messages_path(business_id: @business.id, email_import: 'true')
        else
          return redirect_to messages_path(business_id: @business.id)
        end
      end
    end
    render :index
  end

  private

  def check_ability!
    authorize! :index, self
  end

  def load_data
    @time = params[:time].blank? ? Time.zone.now.to_date : params[:time].to_date
    @graph_by = params[:graph_by].present? ? params[:graph_by] : 'week'
    @business_ids = Business.accessible_by(current_ability).pluck(:id)
    @messages = Message.where(business_id: @business_ids, status: 'finished')
    @total_messages = Time.zone.now.end_of_month.day * current_user.setting_goal.try(:sms_in_day).to_i
    @messages_count = @messages.where(created_at: (Time.zone.now.beginning_of_month..Time.zone.now.end_of_month)).count
    @ratio = (@messages_count / @total_messages.to_f).round(2) * 100
  end

  def import_sms_lists
    @sms_lists = []
    path = params[:csv_file].path
    detection = CharDet.detect(File.read(path))
    encoding = detection['encoding'] == 'Shift_JIS' ? 'CP932' : detection['encoding']
    CSV.foreach(path, headers: true, encoding: "#{encoding}:UTF-8") do |row|
      next if row["name"].blank? || row["tell"].blank? || row["staff"].blank?
      if Staff.accessible_by(current_ability).is_display.where(staffname: row["staff"]).first.blank?
        @cannot_send = true
        flash[:alert] = "「入力値: #{row["staff"]}」のスタッフ名が間違っているか、存在しておりません"
        return
      end
      unless row["tell"][0] == "0"
        row["tell"] = "0" + row["tell"]
      end
      row["tell"]
      @sms_lists << { name: row["name"], tell: row["tell"], staff: row["staff"], send_requested_at: row["requested_date"] }
    end
    if @sms_lists.blank?
      flash[:alert] = "読み込めるリストが1件もありませんでした"
      @cannot_send = true
    end
    send_limit = @sms_lists.count.to_i + current_user.sent_messages.by_month(Time.zone.now).count.to_i
    if send_limit > current_user.max_sms_in_month
      flash[:alert] = "今月の送信上限数(" + current_user.max_sms_in_month.to_s + ")件を超過しております。"
      @cannot_send = true
    end
  end

  def import_email_lists
    @email_lists = []
    path = params[:csv_file].path
    detection = CharDet.detect(File.read(path))
    encoding = detection['encoding'] == 'Shift_JIS' ? 'CP932' : detection['encoding']
    CSV.foreach(path, headers: true, encoding: "#{encoding}:UTF-8") do |row|
      next if row["name"].blank? || row["email"].blank? || row["staff"].blank?
      if Staff.accessible_by(current_ability).is_display.where(staffname: row["staff"]).first.blank?
        @cannot_send = true
        flash[:alert] = "「入力値: #{row["staff"]}」のスタッフ名が間違っているか、存在しておりません"
        return
      end
      @email_lists << { name: row["name"], email: row["email"], staff: row["staff"], send_requested_at: row["requested_date"] }
    end
    if @email_lists.blank?
      flash[:alert] = "読み込めるリストが1件もありませんでした"
      @cannot_send = true
    end
  end

  def import_bulk
    if params[:message][:email_pattern_id].present?
      type = 'email'
    else
      type = 'sms'
    end

    rows = JSON.parse params[:csv_lists]
    rows.each do |row|
      staff_id = Staff.accessible_by(current_ability).is_display.where(staffname: row["staff"]).first.try(:id)
      if type == 'email'
        csv_email_pattern = EmailPattern.find_by(id: params[:message][:email_pattern_id])
        if csv_email_pattern
          @message = @business.messages.new(
            message_type: :email,
            customer_name: row["name"],
            send_requested_at: row["send_requested_at"],
            staff_id: staff_id,
            phone_number: '',
            email: row["email"],
            email_pattern_id: csv_email_pattern.id,
            content_email: (csv_email_pattern.content + "\r\n" + service_review_url(@business))
          )
          @message.sender_id = current_user.id
          @message.save!
        end
      else
        csv_sms_pattern = SmsPattern.find_by(id: params[:message][:sms_pattern_id])
        if csv_sms_pattern
          @message = @business.messages.new(
            message_type: :sms,
            customer_name: row["name"],
            send_requested_at: row["send_requested_at"],
            staff_id: staff_id,
            phone_number: row["tell"],
            sms_pattern_id: csv_sms_pattern.id,
            content: (csv_sms_pattern.content + "\r\n" + service_review_url(@business))
          )
          @message.sender_id = current_user.id
          @message.save!
        end
      end
    end
    flash[:info] = "一斉送信完了しました"
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = @message.errors.full_messages.first
  ensure
    if type == 'email'
      redirect_to messages_path(business_id: @business.id, email_import: 'true')
    else
      redirect_to messages_path(business_id: @business.id)
    end
  end


  def set_content message, business
    content = ''
    if message.sms?
      sms_pattern = SmsPattern.find_by(id: params[:message][:sms_pattern_id])
      content = sms_pattern.content if sms_pattern
      message.content = (content + "\r\n" + service_review_url(business))
    elsif message.email?
      email_pattern = EmailPattern.find_by(id: params[:message][:email_pattern_id])
      content = email_pattern.content if email_pattern
      message.content_email = (content + "\r\n" + service_review_url(business))
    end
  end

  def service_review_url(business)
    if business&.setting_sms&.review_url_enabled && business.review_services_url_exists?
      r_url(id: business.bid).to_s
    else
      ''
    end
  end
end
