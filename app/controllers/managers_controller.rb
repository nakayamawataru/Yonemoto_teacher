class ManagersController < ApplicationController
  before_action :authenticate_user!, :authorize_manager

  def new
    session[:manager_id] = current_user.id unless session[:manager_id].present?
    user = User.find_by(id: params[:user_id])
    if !user.active?
      redirect_to root_path, notice: "#{user.name}アカウントの利用が停止されております。"
    else
      sign_in(user)
      session[:manager_id] = nil if session[:manager_id] == user.id
      redirect_to root_path, notice: "#{user.name}として情報を見る"
    end
  end
end
