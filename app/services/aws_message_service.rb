class AwsMessageService
  class << self
    def dispatch(message)
      message_length = message.try(:bytes).try(:count)
      message = JSON.parse(message).with_indifferent_access rescue nil
      if message
        event = message[:event]
        payload = message[:payload]

        Rails.logger.info("Received message with event: #{event}; payload size: #{message_length} bytes")

        case event.to_s.downcase.to_sym
          when :s3_object_version_added
            attachment = Attachment.where(key: payload[:original_key]).first
            raise RuntimeError.new("Attachment for key #{payload[:original_key]} not found; version not added") unless attachment
            Rails.logger.info("Resolved attachment to which a new version was added; attachment id: #{attachment.id}")
            attachment.add_version(payload)
        end
      end
      nil
    end
  end
end
