class AutoReplyReview
  def self.execute
    user_ids = User.where(auto_reply_reviews_restricted: false).ids
    businesses = Business.active.where(user_id: user_ids)
    current_time = Time.zone.now
    last_time = current_time - 25.hours # 25 hours to cover overlaps review from fetch reviews batch

    businesses.each do |business|
      reviews = business.reviews.not_replied.where(create_time: last_time..current_time)
      next unless reviews.any?

      client = GoogleBusinessApi.new(google_account_id: business.google_account_id, google_account_refresh_token: business.google_account_refresh_token)
      reviews.each do |review|
        return unless review.type_review

        content_reply = business.reply_reviews.find_by(type_review: review.type_review.to_i, auto_reply: true).try(:content).to_s
        return unless content_reply.present?

        response = client.reply_review(business.location_id, review.review_id, content_reply)
        next if response['error'].present?

        review.update(reply_content: response['comment'], reply_update_time: response['updateTime'])
      end
    end
  end
end
