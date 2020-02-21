class CrawlerLamda
  require 'aws-sdk'
  require 'json'

  $crawler_lambda_instance

  def self.get_instance
    if $crawler_lambda_instance.nil?
      $crawler_lambda_instance = CrawlerLamda.new
    end
    $crawler_lambda_instance
  end

  def initialize
    Aws.config.update({
      credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'],
                                        ENV['AWS_SECRET_ACCESS_KEY'])
    })
    @client = Aws::Lambda::Client.new(region: ENV['AWS_REGION'])
  end

  def crawler business, keyword_need_crawlers
    keywords = keyword_need_crawlers.map {|k| { id: k.id, value: k.value }}
    if business.base_location_crawler
      req_payload = { base_location: business.base_location_crawler,
                      base_location_japanese: business.base_address,
                      keywords: keywords,
                      business: {
                        id: business.id,
                        name: business.name,
                        cid: business.map_url.to_s.split('=').last
                      },
                      benchmark_business: business.benchmark_business.map {|b| { id: b.id, name: b.name }},
                      date: Time.now.strftime('%Y-%m-%d'),
                    }
      payload = JSON.generate(req_payload)
      # Run function lamda
      @client.invoke_async({
        function_name: ENV['FUNCTION_NAME_LAMDA_CRAWLER'],
        invoke_args: payload
      })
    end
  end
end