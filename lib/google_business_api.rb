require 'google/api_client/client_secrets'

class GoogleBusinessApi
  attr_reader :parameters, :google_token, :account_id, :authorization, :refresh_token

  def initialize(options={})
    @account_id = options[:google_account_id]
    @refresh_token = options[:google_account_refresh_token]
    raise 'Google Token NotFound' if @account_id.blank?
    @base_url = "https://mybusiness.googleapis.com/v4/accounts/#{@account_id}"
    @parameters = {}
    @parameters['access_token'] = google_access_token
  end

  def list_locations(page_token)
    @parameters['pageToken'] = page_token if page_token.present?
    request_url = @base_url + '/locations?' + query_string
    result = HTTParty.try :get, request_url
    result.parsed_response
  end

  def get_location(location_id)
    request_url = "#{@base_url}/locations/#{location_id}?#{query_string}"
    result = HTTParty.try :get, request_url
    result.parsed_response
  end

  def list_reviews(location_id, page_token)
    @parameters['pageToken'] = page_token if page_token.present?
    request_url = @base_url + "/locations/#{location_id}/reviews?" + query_string
    result = HTTParty.try :get, request_url
    result.parsed_response
  end

  def list_reviews_batch(location_ids, page_token)
    request_url = @base_url + "/locations:batchGetReviews?" + query_string
    locationNames = []
    location_ids.each{|location_id| locationNames << "accounts/#{@account_id}/locations/#{location_id}" }

    request_body = {
      "locationNames": locationNames,
      "pageSize": 4000, # Get 4000 reviews in each request
      "pageToken": page_token
    }

    result = HTTParty.post(request_url, :body => request_body.to_json, :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'})
    result.parsed_response
  end

  def fetch_insights(metric, time_range, location_id, options)
    request_url = @base_url + "/locations:reportInsights?" + query_string
    request_body = {
      "locationNames" => ["accounts/#{@account_id}/locations/#{location_id}"],
      "basicRequest" => {
        "metricRequests" => [
          {
            "metric" => metric,
            "options" => [ options ]
          }
        ],
        "timeRange" => {
          "startTime" => time_range.first,
          "endTime" => time_range.last
        }
      }
    }
    result = HTTParty.post(request_url, :body => request_body.to_json, :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'})
    result.parsed_response
  end

  def reply_review(location_id, review_id, content)
    # GMBのデータ変更するAPIです
    # 本番からしか動けないようにした方が安全
    return unless Rails.env.production?

    request_url = "#{@base_url}/locations/#{location_id}/reviews/#{review_id}/reply?#{query_string}"
    request_body = {
      comment: content
    }

    result = HTTParty.put(request_url, :body => request_body.to_json, :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'})
    result.parsed_response
  end

  def delete_reply_review(location_id, review_id)
    # GMBのデータ変更するAPIです
    # 本番からしか動けないようにした方が安全
    return unless Rails.env.production?

    request_url = "#{@base_url}/locations/#{location_id}/reviews/#{review_id}/reply?#{query_string}"
    request_body = {}

    result = HTTParty.delete(request_url, :body => request_body.to_json, :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'})
    result.parsed_response
  end

  def post_what_news(location_id, post)
    # GMBのデータ変更するAPIです
    # 本番からしか動けないようにした方が安全
    return unless Rails.env.production?

    request_url = @base_url + "/locations/#{location_id}/localPosts?" + query_string
    request_body = {
      "languageCode": "ja",
      "topicType": "STANDARD",
      "summary": post.summary
    }

    if post.action_type.present? && post.action_type != 'N0_ACTION'
      request_body[:callToAction] = {
        "actionType": post.action_type,
        "url": post.action_url,
      }
    end

    if post.image_url.present?
      request_body[:media] = [
        {
          "mediaFormat": "PHOTO",
          "sourceUrl": post.image_url,
        }
      ]
    end

    result = HTTParty.post(request_url, :body => request_body.to_json, :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'})
    result.parsed_response
  end

  def post_event(location_id, post)
    # GMBのデータ変更するAPIです
    # 本番からしか動けないようにした方が安全
    return unless Rails.env.production?

    request_url = @base_url + "/locations/#{location_id}/localPosts?" + query_string
    request_body = {
      "languageCode": "ja",
      "topicType": "EVENT",
      "summary": post.summary,
      "event": {
        "title": post.title,
        "schedule": {
          "startDate": {
            "year": post.start_date.year,
            "month": post.start_date.month,
            "day": post.start_date.day,
          },
          "startTime": {
            "hours": post.start_date.hour,
            "minutes": post.start_date.min,
            "seconds": post.start_date.sec,
            "nanos": 0,
          },
          "endDate": {
            "year": post.end_date.year,
            "month": post.end_date.month,
            "day": post.end_date.day,
          },
          "endTime": {
            "hours": post.end_date.hour,
            "minutes": post.end_date.min,
            "seconds": post.end_date.sec,
            "nanos": 0,
          },
        }
      }
    }

    if post.action_type.present? && post.action_type != 'N0_ACTION'
      request_body[:callToAction] = {
        "actionType": post.action_type,
        "url": post.action_url,
      }
    end

    if post.image_url.present?
      request_body[:media] = [
        {
          "mediaFormat": "PHOTO",
          "sourceUrl": post.image_url,
        }
      ]
    end

    result = HTTParty.post(request_url, :body => request_body.to_json, :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'})
    result.parsed_response
  end

  def post_coupon(location_id, post)
    # GMBのデータ変更するAPIです
    # 本番からしか動けないようにした方が安全
    return unless Rails.env.production?

    request_url = @base_url + "/locations/#{location_id}/localPosts?" + query_string
    request_body = {
      "languageCode": "ja",
      "topicType": "OFFER",
      "summary": post.summary,
      "offer": {
        "couponCode": post.coupon_code,
        "redeemOnlineUrl": post.redeem_online_url,
        "termsConditions": post.terms_conditions
      },
      "event": {
        "title": post.title,
        "schedule": {
          "startDate": {
            "year": post.start_date.year,
            "month": post.start_date.month,
            "day": post.start_date.day,
          },
          "startTime": {
            "hours": post.start_date.hour,
            "minutes": post.start_date.min,
            "seconds": post.start_date.sec,
            "nanos": 0,
          },
          "endDate": {
            "year": post.end_date.year,
            "month": post.end_date.month,
            "day": post.end_date.day,
          },
          "endTime": {
            "hours": post.end_date.hour,
            "minutes": post.end_date.min,
            "seconds": post.end_date.sec,
            "nanos": 0,
          },
        }
      }
    }

    if post.image_url.present?
      request_body[:media] = [
        {
          "mediaFormat": "PHOTO",
          "sourceUrl": post.image_url,
        }
      ]
    end

    result = HTTParty.post(request_url, :body => request_body.to_json, :headers => { 'Content-Type' => 'application/json', 'Accept' => 'application/json'})
    result.parsed_response
  end

  private

  def google_access_token
    secret = Google::APIClient::ClientSecrets.new(
      { 'web' =>
        {
          'refresh_token' => @refresh_token,
          'client_id' => ENV['GOOGLE_CLIENT_ID'],
          'client_secret' => ENV['GOOGLE_CLIENT_SECRET'],
        }
      }
    )
    @authorization = secret.to_authorization
    @authorization.refresh!
    @authorization.access_token
  end

  def query_string
    if @authorization.expired?
      @authorization.refresh!
      @parameters['access_token'] = @authorization.access_token
    end
    @parameters.sort.map do |key, value|
      [URI.escape(key.to_s, Regexp.new('[^#{URI::PATTERN::UNRESERVED}]')),
      URI.escape(value.to_s, Regexp.new('[^#{URI::PATTERN::UNRESERVED}]'))].join('=')
    end.join('&')
  end
end
