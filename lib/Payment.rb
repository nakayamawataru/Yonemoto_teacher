class Payment

  Payjp::api_key = ENV['PAYJP_PRIVATE_KEY']
  #
  # カードトークンを用いて支払いを作成する
  #
  def self.create_charge_by_token(token, amount)
    Payjp::Charge.create(
      amount:   amount,
      card:     token,
      currency: 'jpy'
    )
  end

  #
  # 顧客を用いて支払いを作成する
  #
  def self.create_charge_by_customer(customer, amount)
    Payjp::Charge.create(
      amount:   amount,
      customer: customer,
      currency: 'jpy'
    )
  end

  #
  # プランを作成する
  #
  def self.create_plan(amount, interval = 'month')
    Payjp::Plan.create(
      amount:   amount,
      interval: interval,
      currency: 'jpy'
    )
  end

  #
  # 定額課金を作成する
  #
  def self.create_subscription(customer, plan)
    Payjp::Subscription.create(
      customer: customer,
      plan:     plan,
    )
  end

end
