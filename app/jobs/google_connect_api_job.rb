class GoogleConnectApiJob
  include SuckerPunch::Job

  def perform(business_id, location_id)
    business = Business.find(business_id)
    location = business.get_google_location(location_id)

    if location["error"].present?
      error_status = location["error"]["code"] == 404 ? Business.gmb_connect_statuses[:not_match] : Business.gmb_connect_statuses[:api_errors]

      return business.update!(gmb_connect_status: error_status)
    end
    business.update_info(location)
    business.save!
  rescue Exception => e
    logger.error "There was an exception - #{e.class}(#{e.message})"
    logger.error e.backtrace.join("\n")
  end
end
