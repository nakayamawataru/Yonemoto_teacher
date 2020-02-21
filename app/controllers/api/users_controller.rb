class Api::UsersController < ApplicationController
  def benchmark_business_limit
    user_id =  params[:user_id]
    user = User.find_by id: user_id
    benchmark_business_limit = user.try(:nested_owner_benchmark_business_limit) || 3

    render json: { benchmark_business_limit: benchmark_business_limit }
  end
end
