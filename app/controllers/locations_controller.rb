class LocationsController < BaseController
  skip_authorize_resource
  skip_before_action :build_instance, :set_params

  def index
    return redirect_to root_path unless current_user.admin?

    @connected_list = []
    @available_list = []
    client = GoogleBusinessApi.new
    locations = []
    next_page_token = ''
    loop do
      result = client.list_locations next_page_token
      break if result.blank? || result.try(:[], 'locations').blank?
      locations += result['locations']
      next_page_token = result['nextPageToken']
      break if next_page_token.blank?
    end
    return if locations.blank?

    item_list = locations.map { |l| {primary_phone: l['primaryPhone'], location_name: l['locationName'], postal_code: l['address']['postalCode']} }.uniq.compact
    item_list.each do |item|
      if Business.find_by(primary_phone: item[:primary_phone], postal_code: item[:postal_code])
        @connected_list << item
      else
        @available_list << item
      end
    end
  end
end
