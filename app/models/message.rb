# == Schema Information
#
# Table name: messages
#
#  id                :bigint           not null, primary key
#  content           :text(65535)
#  content_email     :text(65535)
#  customer_name     :string(255)      not null
#  email             :string(255)
#  message_type      :integer          default("sms")
#  phone_number      :string(255)      not null
#  send_date         :datetime         not null
#  send_requested_at :datetime
#  status            :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  business_id       :bigint           not null
#  email_pattern_id  :integer
#  sender_id         :bigint           not null
#  sms_pattern_id    :integer
#  staff_id          :bigint           not null
#
# Indexes
#
#  index_messages_on_business_id  (business_id)
#  index_messages_on_sender_id    (sender_id)
#  index_messages_on_staff_id     (staff_id)
#

class Message < ApplicationRecord
  DEFAULT_UPDATABLE_ATTRIBUTES = %i[staff_id business_id phone_number customer_name send_requested_at
    sms_pattern_id content_email email message_type email_pattern_id]

  enum status: {finished: 1, failed: 0, requested: 2}
  enum message_type: {sms: 1, email: 2}

  belongs_to :staff
  belongs_to :sender, class_name: 'User', foreign_key: 'sender_id'
  belongs_to :business
  belongs_to :sms_pattern, optional: true
  belongs_to :email_pattern, optional: true

  validates :status, :send_date, :customer_name, presence: true
  validates :phone_number, presence: true, if: Proc.new { |p| p.sms? }
  validates :sms_pattern_id, presence: true, if: Proc.new { |p| p.sms? }
  validates :email, presence: true, if: Proc.new { |p| p.email? }
  validates :email_pattern_id, presence: true, if: Proc.new { |p| p.email? }
  validate :check_send_requested_at

  before_validation :set_attributes_and_send_sms, on: :create

  scope :by_month, ->(time){where(send_date: (time.beginning_of_month..time.end_of_month))}
  scope :by_day, ->(time){where(send_date: (time.beginning_of_day..time.end_of_day))}

  def week
    send_date.beginning_of_week.strftime("%m/%d〜")
  end

  def day
    send_date.strftime("%m/%d〜")
  end

  def month
    send_date.beginning_of_month.strftime("%m/%d〜")
  end

  private

  def set_attributes_and_send_sms
    self.send_date = Time.zone.now
    self.content = init_content(try(:content).to_s)

    begin
    if email?
      raise if self.content_email.blank?
      if send_requested_at.present?
        self.status = Message.statuses[:requested]
      else
        MessageMailer.send_message(email, content_email).deliver_later
        self.status = Message.statuses[:finished]
      end
    elsif sms?
      raise if self.content.blank?
      if send_requested_at.present?
        self.status = Message.statuses[:requested]
      else
        TwilioTextMessenger.new(self.phone_number, self.content).call
        self.status = Message.statuses[:finished]
      end
    end
    rescue
      self.status = Message.statuses[:failed]
    end
  end

  def init_content(content)
    return '' if content.blank?
    content = content.gsub('[お客様名]', self.customer_name) if content.match?("お客様名")
    content = content.gsub('[店舗名]', self.business.name) if self.business.present? && content.match?("店舗名")
    return content
  end

  def check_send_requested_at
    if self.send_requested_at && self.send_requested_at < Time.zone.now
      errors.add(:send_requested_at, "現在時刻より先の日付で登録をお願いします")
    end
  end

  def self.exec_requested_sms
    from = Time.zone.now - 1.days
    to   = Time.zone.now
    messages = Message.sms.where(send_requested_at: from..to, status: 'requested')
    return if messages.blank?
    messages.each do |message|
      begin
        if Rails.env.production?
          TwilioTextMessenger.new(message.phone_number, message.content).call
          message.update_attribute(:status, Message.statuses[:finished])
        end
      rescue
        message.update_attribute(:status, Message.statuses[:failed])
        CrawlerMailer.sms_error(message).deliver_later
        next
      end
    end
  end

  def self.exec_requested_email
    from = Time.zone.now - 1.days
    to   = Time.zone.now
    messages = Message.email.where(send_requested_at: from..to, status: 'requested')
    return if messages.blank?
    messages.each do |message|
      begin
        MessageMailer.send_message(message.email, message.content_email).deliver_later
        message.update_attribute(:status, Message.statuses[:finished])
      rescue
        message.update_attribute(:status, Message.statuses[:failed])
        MessageMailer.email_error(message).deliver_later
        next
      end
    end
  end
end
