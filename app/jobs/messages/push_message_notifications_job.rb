class PushMessageNotificationsJob
  include Unicorn::Notifications

  @queue = :high

  class << self
    def perform(message_id)
      new(message_id).process
    end
  end

  def initialize(message_id)
    @message = Message.find(message_id)
  end

  def process
    send_push_notifications
  end

  private

  def message_json
    Rabl::Renderer.new('messages/show',
                       @message,
                       view_path: 'app/views',
                       format: 'hash').render
  end

  def mobile_notification_params
    { message: message_json }.merge(
      {
        alert: {
          title: "#{@message.sender.name.split(/ /)[0].strip} said:",
          body: @message.body,
        },
        badge: '+1',
        sound: 'default',
      }
    )
  end

  def users
    @users ||= [@message.recipient]
  end

  def websocket_notification_params
    { message: 'message_received', payload: message_json }
  end
end
