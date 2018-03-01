module Notifiable
  extend ActiveSupport::Concern

  included do
    has_many :notifications, as: :notifiable

    after_commit :send_changed_notifications

    private

    def notification_params(notification_type)
      {}
    end

    def notification_recipients(notification_type)
      []
    end

    def send_changed_notifications
      type = "#{self.class.to_s.underscore}_changed"
      slug = "#{type}_#{self.id}_#{self.object_id}"
      slug = "#{slug}_#{self.status}" if self.respond_to?(:status)

      return unless send_notification?(type.to_sym)

      recipients = notification_recipients(type.to_sym)
      params = notification_params(type.to_sym)

      recipients.each do |recipient|
        next if notifications.where(recipient_id: recipient.id,
                                    type: type,
                                    slug: slug).count > 0

        notifications.create(recipient: recipient,
                             type: type,
                             slug: slug,
                             params: params) rescue nil
      end if recipients.is_a?(Array)
    end

    def send_notification?(notification_type)
      true
    end
  end
end
