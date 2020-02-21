# Mail test
# bounce@simulator.amazonses.com
# complaint@simulator.amazonses.com

class AmazonMailSqsService
  EMAIL_TYPES = [:Bounce, :Complaint]

  class << self
    def execute
      return unless Rails.env.production?
      return unless ENV['AWS_SQS_QUEUE_URL']

      queue_url = ENV['AWS_SQS_QUEUE_URL']
      poller_options = {
        wait_time_seconds: nil,
        skip_delete: false,
        visibility_timeout: 60,
        idle_timeout: 20
      }
      # max_poll_messages = 20
      Aws.config.update amazon_credential_sqs_configs
      poller = Aws::SQS::QueuePoller.new queue_url, poller_options
      # stop_queue_polling poller, max_poll_messages

      email_list = {
        Bounce: [],
        Complaint: []
      }

      poller.poll do |queue_message|
        begin
          message_body = queue_body_parse queue_message.try(:body)
          notification_message = queue_body_parse message_body[:Message]
          notification_type = notification_message[:notificationType].to_sym
          next unless EMAIL_TYPES.include? notification_type

          email_list[notification_type] << notification_message[:mail].try(:[], 'destination')
        rescue StandardError => e
          p "There was an exception - #{e.class}(#{e.message})"
          p e.backtrace.join("\n")
        end
      end

      import_emails email_list
    end

    def amazon_credential_sqs_configs
      {
        region: ENV['AWS_SES_REGION'],
        access_key_id: ENV['AWS_SES_ACCESS_KEY_ID'],
        secret_access_key: ENV['AWS_SES_SECRET_ACCESS_KEY']
      }
    end

    def stop_queue_polling poller, max_poll_messages
      poller.before_request do |stats|
        throw :stop_polling if stats.received_message_count >= max_poll_messages
      end
    end

    def queue_body_parse queue_body
      queue_body_obj = JSON.parse queue_body
      queue_body_obj.symbolize_keys
    rescue JSON::ParserError => json_parser_error
      raise "Error parse queue message body: #{json_parser_error}"
    end

    def import_emails email_list
      new_emails = []
      EMAIL_TYPES.each do |email_type|
        next unless email_list[email_type].any?

        emails = email_list[email_type].flatten.compact
        emails.each do |email|
          SesBlacklistEmail.find_or_create_by(email: email, email_type: email_type)
        end
        new_emails += emails
      end
      SesMailer.bounce_email_notify(new_emails).deliver_later if new_emails.any?
      email_list
    end
  end
end
