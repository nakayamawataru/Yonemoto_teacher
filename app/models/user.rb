# == Schema Information
#
# Table name: users
#
#  id                              :bigint           not null, primary key
#  auto_post_restricted            :boolean          default(TRUE)
#  auto_reply_reviews_restricted   :boolean          default(TRUE)
#  benchmark_business_limit        :integer          default(3)
#  card                            :text(65535)
#  color                           :string(255)
#  company                         :string(255)      not null
#  coupon_restricted               :boolean          default(TRUE)
#  deleted_at                      :datetime
#  demo_at                         :datetime
#  email                           :string(191)      not null
#  encrypted_password              :string(255)      not null
#  expire_at                       :datetime
#  gmb_restricted                  :boolean          default(FALSE)
#  header_color                    :string(255)
#  header_logo                     :string(255)
#  keyword_count                   :integer          default(0)
#  logo                            :string(255)
#  logo_target_url                 :string(255)
#  manual_reply_reviews_restricted :boolean          default(TRUE)
#  max_sms_in_day                  :integer          default(50)
#  max_sms_in_month                :integer          default(50)
#  name                            :string(255)      not null
#  payjp_card_token                :string(255)
#  payment_discount                :integer          default(0)
#  phone_number                    :string(255)      not null
#  pre_keyword_count               :integer          default(0)
#  remember_created_at             :datetime
#  reset_password_sent_at          :datetime
#  reset_password_token            :string(191)
#  restricted                      :boolean          default(FALSE)
#  role                            :integer
#  setting_calendar                :integer          default("default_calendar")
#  setting_memo                    :integer          default("default_memo")
#  skin_theme                      :string(255)
#  temp_keyword_count              :integer          default(0)
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  agent_id                        :integer
#  payjp_customer_id               :string(255)
#  plan_id                         :integer
#
# Indexes
#
#  index_users_on_deleted_at            (deleted_at)
#  index_users_on_email_and_deleted_at  (email,deleted_at) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#

class User < ApplicationRecord
  include ActionView::Helpers::UserHelper
  # 重要なので外さないでください - Important! Do not remove!
  acts_as_paranoid
  serialize :card

  serialize :card

  mount_uploader :logo, ImageUploader
  mount_uploader :header_logo, ImageUploader

  DEFAULT_UPDATABLE_ATTRIBUTES =
    %i[email password role agent_id name company phone_number logo color header_color header_logo restricted plan_id
      coupon_restricted gmb_restricted expire_at max_sms_in_day logo_target_url benchmark_business_limit
      manual_reply_reviews_restricted auto_reply_reviews_restricted auto_post_restricted skin_theme
      setting_calendar setting_memo]
  DEMO_PERIOD = 10
  DEMO_BUSINESS_MAX = 1
  DEMO_KEYWORD_MAX = 2

  enum role: [:user, :agent, :admin, :owner, :agent_meo_check, :demo_user]
  enum setting_calendar: { default_calendar: 1, super_regional_calendar: 2 }
  enum setting_memo: { default_memo: 1, super_regional_memo: 2 }

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]
  has_many :users, class_name: "User", foreign_key: "agent_id"
  has_many :businesses, dependent: :destroy
  has_many :business_owners, through: :businesses, source: :owner, dependent: :destroy
  has_many :staffs
  has_many :sent_messages, class_name: 'Message', foreign_key: 'sender_id'
  has_many :payment_histories, dependent: :destroy
  has_many :keyword_reviews, dependent: :destroy

  has_one :owner_business, foreign_key: :owner_id, class_name: Business.name, dependent: :nullify
  has_one :setting_goal, dependent: :destroy
  belongs_to :plan

  scope :by_agent_ids, ->(agent_ids) { where(agent_id: agent_ids) }

  belongs_to :agent, optional: true, class_name: "User"

  validates :name, :email, :company, :phone_number, presence: true
  validates :email, uniqueness: true
  validate :only_allow_agent_for_user_and_owner
  validates_format_of :color, with: /#(?:[A-F0-9]{3}){1,2}/i, if: Proc.new { |c| c.color.present? }
  validates_format_of :header_color, with: /#(?:[A-F0-9]{3}){1,2}/i, if: Proc.new { |c| c.header_color.present? }

  after_initialize :set_default_role, if: :new_record?
  before_destroy :change_staff_owner

  def set_default_role
    self.role ||= :user
  end

  def active_for_authentication?
    # super && active?
    super
  end

  def active?
    self.expire_at.blank? || (self.expire_at.present? && self.expire_at > Time.zone.now)
  end

  def nested_agent
    return self if self.agent?
    return self.agent if self.agent.present? && self.agent.agent?
    if self.owner? && self.owner_business.present? && self.owner_business.user.present?
      owner_user = self.owner_business.user
      return owner_user if owner_user.agent?
      return owner_user.agent if owner_user.agent.present? && owner_user.agent.agent?
    end
  end

  def demo_remained_date
    ( self.expire_at.to_date - Time.zone.now.to_date ).to_i
  end

  def nested_owner_present?
    return true if self.is_agent?
    return true if self.agent.present?
    return (self.owner_business&.user&.is_agent? || self.owner_business&.user&.agent.present?) if self.owner?
    return false
  end

  def nested_owner
    ob_nested_owner = nil
    ob_nested_owner = self if self.is_agent?
    if self.nested_owner_present?
      ob_nested_owner = self.agent if self.agent.present?
      if self.owner?
        owner_user = self.owner_business.user
        ob_nested_owner = owner_user if owner_user.is_agent?
        ob_nested_owner = owner_user.agent if owner_user.agent.present?
      end
    end

    return ob_nested_owner
  end

  def nested_owner_name
    nested_owner ? nested_owner.try(:company).to_s : '-'
  end

  def nested_owner_color
    color = nested_owner.try(:skin_theme)
    color = "skin-" + color if color.present?

    return color.presence || 'skin-green'
  end

  def nested_owner_benchmark_business_limit
    return self.benchmark_business_limit if self.is_agent?
    if self.nested_owner_present?
      return self.agent.benchmark_business_limit if self.agent.present?
      if self.owner?
        owner_user = self.owner_business.user
        return owner_user.benchmark_business_limit if owner_user.is_agent?
        return owner_user.agent.benchmark_business_limit if owner_user.agent.present?
      end
    end

    (nested_owner ? nested_owner : self).benchmark_business_limit
  end

  #  coupon_restricted クーポン機能
  #  gmb_restricted    GMB機能
  #  restricted        星カクトくん
  def check_message_plan
    if !coupon_restricted && !gmb_restricted && !restricted
      name  = '星カクトくんGMB'
      price = 11000
    elsif !gmb_restricted && !restricted
      name  = '星カクトくんGMB'
      price = 11000
    elsif !coupon_restricted && !restricted
      name  = '星カクトくん＋'
      price = 8800
    elsif !restricted
      name  = '星カクトくん'
      price = 7700
    end
    return nil if name.blank?
    return name, price
  end

  def is_agent?
    agent? || agent_meo_check?
  end

  def is_user?
    user? || demo_user?
  end

  def managing_businesses
    is_agent? ? Business.where(user_id: [id] + users.ids) : businesses
  end

  def display_name_for_dropdown
    if company == name
      "#{id} - #{company} - #{email} - #{role_as_text(role)}"
    else
      "#{id} - #{company} - #{name} - #{email} - #{role_as_text(role)}"
    end
  end

  def payment?
    payment_active? || active?
  end

  def rate_payment(current_month=false)
    rate = 1
    month_payment = current_month ? Time.zone.now : Time.zone.now.last_month

    if demo_at.present?
      expire_date = demo_at + 10.days
      if expire_date.try(:month).to_i == month_payment.month
        day_end_month = month_payment.end_of_month.day
        rate = ((day_end_month - expire_date.try(:day).to_i)/day_end_month.to_f).round(2)
      end
    end

    rate
  end

  def payed_at(current_month=false)
    month_payment = current_month ? Time.zone.now : Time.zone.now.last_month
    date = month_payment.beginning_of_month
    date = demo_at + 10.days if demo_at.present? && (demo_at + 10.days).try(:month).to_i == month_payment.month

    date
  end

  def payment_active?
    payjp_customer_id.present? && card.present?
  end

  def agent_setting
    self.agent.present? && self.agent.is_agent? ? self.agent : self
  end

  private

  def change_staff_owner
    return unless owner? || user?
    if owner? || agent.nil?
      staffs.destroy_all
    else
      staffs.update_all(user_id: agent.id)
    end
  end

  def only_allow_agent_for_user_and_owner
    return if user? || owner?
    errors.add(:agent, "はユーザータイプ以外に設定できません") if agent.present?
  end
end
