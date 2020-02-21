class PlacesApi
  def initialize(business, keyword = nil)
    @parameters = {}
    @parameters['location'] = "#{business.base_lat},#{business.base_long}"
    @parameters['query'] = keyword if keyword.present?
    @parameters['key'] = ENV['GOOGLE_PLACES_API_KEY']
  end

  def retrieve_ranking
    base_url = 'https://maps.googleapis.com/maps/api/place/textsearch/json?'
    request_url = base_url + query_string(@parameters)
    result = HTTParty.try :get, request_url
    result.parsed_response
  end

  def query_string(parameters)
    parameters.sort.map do |key, value|
      [URI.escape(key.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")),
      URI.escape(value.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))].join("=")
    end.join("&")
  end
end
