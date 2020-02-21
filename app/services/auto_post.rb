class AutoPost
  def self.execute(time_span=30)
    current_time = Time.zone.now
    from_time = current_time - time_span.minutes
    user_ids = User.where(auto_post_restricted: false).ids
    businesses = Business.active.where(user_id: user_ids)

    post_log = []
    businesses.each do |business|
      posts = business.posts.where(status: [:pending, :failed], time_post: (from_time..current_time), auto_post: true)
      next unless posts.any?

      client = GoogleBusinessApi.new(google_account_id: business.google_account_id, google_account_refresh_token: business.google_account_refresh_token)
      posts.each do |post|
        response =
          if post.what_news?
            client.post_what_news(business.location_id, post)
          elsif post.event?
            client.post_event(business.location_id, post)
          elsif post.coupon?
            client.post_coupon(business.location_id, post)
          end

        if response && !response['error'].present?
          post.successed!
          post_log << {id: post.id, status: 'ok'}
        else
          post.failed!
          post_log << {id: post.id, status: 'fail'}
        end
      end
    end
    post_log
  end
end
