class PushNotificationJob
  include Unicorn::Notifications

  @queue = :high

  class << self
    def perform(notification_id, params = {})
      new(notification_id, params).process
    end
  end

  def initialize(notification_id, params)
    @notification = Notification.unscoped.find(notification_id) rescue nil
    @params = params || {}
    @params.symbolize_keys! if @params.is_a?(Hash)
  end

  def process
    if deliver?
      send_push_notifications
      notification.update_attribute(:delivered_at, DateTime.now)
    else
      notification.update_attribute(:suppressed_at, DateTime.now)
    end
  end

  private

  def deliver?
    true
  end

  def notification
    @notification
  end

  def params
    @params
  end

  def users
    @users ||= begin
      [notification.recipient]
    end
  end

  def mobile_notification_params
    mobile_notification_params = {
        type: notification.type.to_s
    }.merge(params)
    mobile_notification_params[:"#{notification.notifiable_type.underscore}_id"] = notification.notifiable_id
    mobile_notification_params
  end

  def websocket_notification_params
    payload = Rabl::Renderer.new("#{notification.notifiable.class.name.underscore.pluralize}/show",
                                 notification.notifiable,
                                 view_path: 'app/views',
                                 format: 'hash',
                                 locals: params).render rescue nil

    { message: notification.type.to_s, payload: payload } if payload
  end
end
