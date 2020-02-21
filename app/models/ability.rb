# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    nested_owner = user.nested_owner

    if user.admin?
      can :manage, :all
      cannot :destroy, User, id: user.id
    elsif user.is_agent?
      can [:new, :create], Message
      can :read, Message, sender_id: user.users.pluck(:id) << user.id

      can [:new, :create], User
      can [:read, :edit, :update, :destroy], User, agent_id: user.id
      can [:read, :edit, :update], User, id: user.id

      can [:new, :create], Business
      can [:destroy], Business, user_id: user.users.pluck(:id) << user.id
      can [:read, :edit, :update, :connect_google_location, :update_memo, :edit_memo], Business, user_id: user.users.pluck(:id) << user.id
      can :manage, Memo, user_id: user.users.ids << user.id

      can [:new, :create], Staff
      can [:read, :edit, :update], Staff, user_id: user.users.pluck(:id) << user.id

      can :crud, SettingQr
      can :crud, SettingGoal
      can :crud, SettingSms
      can :manage, ReplyReview, business_id: (user.businesses.pluck(:id) << user.users.joins(:businesses).pluck('businesses.id').uniq).flatten unless user.auto_reply_reviews_restricted
      can :manage, KeywordReview
      can :index, Setting::QaReviewsController

      can :index, CouponsController unless user.coupon_restricted
      can [:new, :create], Coupon
      can [:read, :edit, :update, :sms, :preview], Coupon, business_id: (user.businesses.pluck(:id) << user.users.joins(:businesses).pluck('businesses.id').uniq).flatten

      can [:new], Post unless user.auto_post_restricted
      can :manage, Post, business_id: (user.businesses.pluck(:id) << user.users.joins(:businesses).pluck('businesses.id').uniq).flatten unless user.auto_post_restricted

      can :index, MessagesController unless user.restricted
      can :index, ReviewsController unless user.restricted
      can :fetch, Review
      can [:read, :export_csv], Review, business_id: (user.businesses.pluck(:id) << user.users.joins(:businesses).pluck('businesses.id').uniq).flatten
      can :index, Setting::WidgetsController unless user.restricted

      can :index, ChartsController unless user.gmb_restricted
      can :index, CalendarsController unless user.gmb_restricted
      can :index, ReportsController unless user.gmb_restricted
      can :index, InsightsController unless user.gmb_restricted
      cannot :fetch, Insight
      can :index, ExportsCsvController unless user.gmb_restricted
      can :index, BaseLocationsController unless user.gmb_restricted
      can :index, AlertsController unless user.gmb_restricted

      can :index, CalculatePaymentAmountsController if user.agent?
      cannot :estimate, PaymentsController if nested_owner && (nested_owner.agent? || (nested_owner.agent_meo_check? && nested_owner.plan_id == Plan::RENTAL))
    elsif user.owner?
      can [:new, :create], Message
      can :read, Message, sender_id: user.id

      can [:new, :create], Business
      can [:read, :edit, :update, :connect_google_location, :update_memo, :edit_memo], Business, owner_id: user.id
      can :manage, Memo, user_id: user.id

      can [:new, :create], Staff
      can [:read, :edit, :update], Staff, user_id: user.id

      can :crud, SettingQr
      can :crud, SettingGoal
      can :crud, SettingSms
      can :manage, ReplyReview, business_id: user.owner_business&.id unless user.auto_reply_reviews_restricted
      can :index, Setting::QaReviewsController

      can :index, CouponsController unless user.coupon_restricted
      can [:new, :create], Coupon
      can [:read, :edit, :update, :sms, :preview], Coupon, business_id: user.owner_business&.id

      can [:new], Post unless user.auto_post_restricted
      can :manage, Post, business_id: user.owner_business&.id unless user.auto_post_restricted

      can :index, MessagesController unless user.restricted
      can :index, ReviewsController unless user.restricted
      can :fetch, Review
      can [:read, :export_csv], Review, business_id: user.owner_business&.id
      can :index, Setting::WidgetsController unless user.restricted

      can :index, ChartsController unless user.gmb_restricted
      can :index, CalendarsController unless user.gmb_restricted
      can :index, ReportsController unless user.gmb_restricted
      can :index, InsightsController unless user.gmb_restricted
      cannot :fetch, Insight
      can :index, BaseLocationsController unless user.gmb_restricted

      cannot :index, AlertsController
      cannot :index, CalculatePaymentAmountsController
      cannot :update_payment_discount, UsersController
      cannot [:index, :edit, :update], PaymentsController
      cannot :estimate, PaymentsController if nested_owner && (nested_owner.agent? || (nested_owner.agent_meo_check? && nested_owner.plan_id == Plan::RENTAL))
    else
      can [:new, :create], Message
      can :read, Message, sender_id: user.id

      can [:read], User, id: user.id

      can [:new, :create], Business
      can [:destroy], Business, user_id: user.id if user.agent.nil?
      can [:read, :edit, :update, :connect_google_location, :update_memo, :edit_memo], Business, user_id: user.id
      can :manage, Memo, user_id: user.id

      can [:new, :create], Staff
      can [:read, :edit, :update], Staff, user_id: user.id

      can :crud, SettingQr
      can :crud, SettingGoal
      can :crud, SettingSms
      can :manage, ReplyReview, business_id: user.businesses.pluck(:id) unless user.auto_reply_reviews_restricted
      can :manage, KeywordReview
      can :index, Setting::QaReviewsController

      can :index, CouponsController unless user.coupon_restricted
      can [:new, :create], Coupon
      can [:read, :edit, :update, :sms, :preview], Coupon, business_id: user.businesses.pluck(:id)

      can [:new, :create], Post unless user.auto_post_restricted
      can :manage, Post, business_id: user.businesses.pluck(:id) unless user.auto_post_restricted

      can :index, MessagesController unless user.restricted
      can :index, ReviewsController unless user.restricted
      can :fetch, Review
      can [:read, :export_csv], Review, business_id: user.businesses.pluck(:id)
      can :index, Setting::WidgetsController unless user.restricted

      can :index, ChartsController unless user.gmb_restricted
      can :index, CalendarsController unless user.gmb_restricted
      can :index, ReportsController unless user.gmb_restricted
      can :index, InsightsController unless user.gmb_restricted
      cannot :fetch, Insight
      can :index, ExportsCsvController unless user.gmb_restricted
      can :index, BaseLocationsController unless user.gmb_restricted

      cannot :index, AlertsController
      cannot :index, CalculatePaymentAmountsController
      cannot :update_payment_discount, UsersController
      cannot [:index, :edit, :update], PaymentsController
      cannot :estimate, PaymentsController if nested_owner && (nested_owner.agent? || (nested_owner.agent_meo_check? && nested_owner.plan_id == Plan::RENTAL))
    end

    can :read, BaseLocation
  end
end
