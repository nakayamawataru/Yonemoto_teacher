class Api::BaseLocationsController < ApplicationController
  def find_base_location
    keyword =  params[:q]
    base_locations =
      BaseLocation.where('base_address LIKE ? or base_address_english LIKE ? ',
        "%#{keyword}%", "%#{keyword}%").limit(20)
    
    render json: base_locations
  end
end
  