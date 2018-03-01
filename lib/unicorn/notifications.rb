module Unicorn
  module Notifications
    extend ActiveSupport::Concern

    included do
      def body
        nil
      end

      def title
        nil
      end

      def icon
        nil
      end

      def mobile_notification_params
        {}
      end

      def users
        []
      end

      def websocket_notification_params
        nil
      end

      def websocket_channel_events
        events = []
        users.each do |user|
          events << { "user_#{user.id}" => :push }
        end
        events
      end

      private

      def gcm_client
        @gcm_client ||= Rails.application.config.gcm_client
      end

      def gcm_notification_hash
        return nil unless body || title || icon
        gcm_notification_hash = {}
        gcm_notification_hash[:body] = body if body
        gcm_notification_hash[:title] = title if title
        gcm_notification_hash[:icon] = icon if icon
        gcm_notification_hash
      end

      def houston_client(bundle_id=nil)
        return Rails.application.config.houston_clients[bundle_id] if bundle_id
        @houston_client ||= Rails.application.config.default_houston_client
      end

      def send_push_notifications
        push_apn_notifications rescue nil
        push_gcm_notifications rescue nil
        push_websocket_notifications rescue nil
      end

      def push_apn_notifications
        return unless houston_client
        users.each do |user|
          user.devices.each do |device|
            next unless device.ios?
            notification = Houston::Notification.new({
                                                         device: device.apns_device_id,
                                                         content_available: true
                                                     }.merge(mobile_notification_params))

            houston_client(device.bundle_id).push(notification)
          end
        end
      end

      def push_gcm_notifications
        return unless gcm_client
        users.each do |user|
          user.devices.each do |device|
            next unless device.android?
            registration_ids = [device.gcm_registration_id]
            options = { data: mobile_notification_params }
            options[:notification] = gcm_notification_hash if gcm_notification_hash
            gcm_client.send_notification(registration_ids, options)
          end
        end
      end

      def push_websocket_notifications
        data = websocket_notification_params
        websocket_channel_events.each do |channel_event|
          channel_event.each do |channel, event|
            WebsocketRails[channel.to_sym].trigger(event.to_sym, data)
          end
        end
      end
    end
  end
end
