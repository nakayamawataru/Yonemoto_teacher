# == Schema Information
#
# Table name: payment_histories
#
#  id                              :bigint           not null, primary key
#  actual_amount                   :integer          default(0)
#  amount                          :integer
#  auto_post_restricted            :boolean          default(TRUE)
#  auto_reply_reviews_restricted   :boolean          default(TRUE)
#  count_payment                   :integer          default(0)
#  coupon_restricted               :boolean          default(FALSE)
#  discount                        :integer          default(0)
#  gmb_restricted                  :boolean          default(FALSE)
#  init_price                      :integer
#  manual_reply_reviews_restricted :boolean          default(TRUE)
#  month_price                     :integer
#  note                            :text(65535)
#  payed_at                        :datetime
#  restricted                      :boolean          default(FALSE)
#  review_price                    :integer
#  status                          :integer          default("pending")
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  plan_id                         :integer
#  user_id                         :integer
#

class PaymentHistory < ApplicationRecord
  belongs_to :user
  belongs_to :plan

  enum status: { pending: 0, success: 1, failed: 2, non_paycard: 3 }

  LIMIT_PAYMENT = 3
  # 50~9,999,999の整数
  MIN_VALUE_PAYMENT = 50

  class << self
    def exec_payment
      from = (Date.current - 1.month).beginning_of_month.beginning_of_day
      to = (Date.current - 1.month).end_of_month.end_of_day
      Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]
      users_payment = User.where(expire_at: nil).or(User.where(expire_at: from..to)).where.not(payjp_customer_id: nil, card: nil)

      users_payment.each do |user|
        payment = user.payment_histories.where(payed_at: from..to).last
        begin
          if payment.pending? && payment.actual_amount > MIN_VALUE_PAYMENT
            # 決済実行
            Payjp::Charge.create(
              amount: payment.actual_amount,
              card: user.card,
              customer: user.payjp_customer_id,
              currency: 'jpy'
            )
            payment.update(count_payment: payment.count_payment + 1)
            payment.success!
          end
        rescue => e
          Raven.capture_exception(e)
          payment.update(count_payment: payment.count_payment + 1)
          if payment.count_payment == LIMIT_PAYMENT
            payment.failed!

            PaymentMailer.payment_failed(user).deliver_later
          end
        end
      end
    end

    def calc_amount
      from = (Date.current - 1.month).beginning_of_month.beginning_of_day
      to = (Date.current - 1.month).end_of_month.end_of_day
      users = User.where(expire_at: nil).or(User.where(expire_at: from..to))

      users.each do |user|
        payments = user.payment_histories.where(payed_at: from..to)
        unless payments.present?
          calc_amount_user(user)
        end
      end
    end

    def calc_amount_user(user)
      plan = user.try!(:plan)
      return unless plan

      begin
        init_price   = 0
        month_price  = 0
        review_price = 0
        init_price = user.payment_histories.present? ? 0 : plan.init_price.to_i
        month_price = user.plan.calc_month_fee(user).to_i
        if message_plan = user.check_message_plan
          review_price = message_plan[1].to_i
        end
        amount = init_price + month_price + review_price
        actual_amount = amount * user.rate_payment - user.payment_discount

        user.payment_histories.create(
          amount: amount,
          actual_amount: actual_amount > 0 ? actual_amount : 0,
          discount: user.payment_discount,
          init_price: init_price,
          month_price: month_price,
          review_price: review_price,
          payed_at: user.payed_at,
          note: "キーワード数　#{user.pre_keyword_count}",
          status: :pending,
          plan: plan,
          coupon_restricted: user.coupon_restricted,
          gmb_restricted: user.gmb_restricted,
          restricted: user.restricted,
          auto_post_restricted: user.auto_post_restricted,
          auto_reply_reviews_restricted: user.auto_reply_reviews_restricted,
          manual_reply_reviews_restricted: user.manual_reply_reviews_restricted
        )
      rescue => e
        user.payment_histories.create(
          amount: 0,
          actual_amount: 0,
          discount: 0,
          init_price: 0,
          month_price: 0,
          review_price: 0,
          note: "決済失敗:　" + e,
          payed_at: user.payed_at,
          status: :pending,
          plan: plan,
          coupon_restricted: user.coupon_restricted,
          gmb_restricted: user.gmb_restricted,
          restricted: user.restricted,
          auto_post_restricted: user.auto_post_restricted,
          auto_reply_reviews_restricted: user.auto_reply_reviews_restricted,
          manual_reply_reviews_restricted: user.manual_reply_reviews_restricted
        )
      end
    end
  end
end
