class PaymentsController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = User.accessible_by(current_ability).find_by(id: params[:user_id])
    return redirect_to root_url unless @user.present?
    @payments = @user.payment_histories.order(payed_at: :desc).take(5)
  end

  def new
    if current_user.blank?
      flash[:alert] = "ログインしてください"
      return redirect_to new_user_session_url
    end
    @plans = Plan.where.not(id: Plan::DEMO)

    render :layout => 'payment'
  end

  def create
    plan = Plan.find_by(id: params[:plan_id])
    if params['payjpToken'].present? && plan
      Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]
      cus = Payjp::Customer.create(
        description: current_user.try!(:company)
      )

      customer = Payjp::Customer.retrieve(cus.id)
      card = customer.cards.create(
        card: params['payjpToken']
      )

      current_user.update(payjp_card_token: cus.id)
      current_user.update(payjp_customer_id: cus.id)
      current_user.update(card: card)
      current_user.update(plan: plan)
      current_user.update(restricted: !params[:restricted].present?)
      current_user.update(coupon_restricted: !params[:coupon_restricted].present?)
      current_user.update(manual_reply_reviews_restricted: !params[:manual_reply_reviews_restricted].present?)
      current_user.update(auto_reply_reviews_restricted: !params[:auto_reply_reviews_restricted].present?)
      current_user.update(auto_post_restricted: !params[:auto_post_restricted].present?)
      current_user.update(expire_at: nil)
      if current_user.demo_user?
        current_user.update(role: :user)
      end

      flash[:success] = "クレジット登録完了しました"
      redirect_to root_url
    end
  end

  def edit
    return redirect_to root_url unless current_user && current_user.admin?
    @payment = PaymentHistory.find(params[:id])
  end

  def update
    @payment = PaymentHistory.find(params[:id])
    if @payment.update payment_params
      flash[:success] = "決済情報を更新しました"
      redirect_to payments_url(user_id: params[:user_id])
    else
      flash[:error] = "エラーが発生しました"
      render :edit
    end
  end

  def estimate
    authorize! :estimate, self
  end

  private

  def payment_params
    params.require(:payment_history).permit(
      :amount, :status, :note,
      :init_price, :month_price, :review_price
    )
  end
end
