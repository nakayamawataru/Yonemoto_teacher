# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  private

  def sign_up_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :company, :phone_number)
      .merge(
        plan_id: Plan::ENTRY,
        expire_at: Time.zone.now + User::DEMO_PERIOD.days,
        demo_at: Time.zone.now,
        gmb_restricted: false,
        coupon_restricted: true,
        restricted: true,
        role: User.roles[:demo_user]
      )
  end

  def after_sign_up_path_for(resource)
    UserMailer.register_demo_user(resource).deliver_later

    root_path
  end
end
