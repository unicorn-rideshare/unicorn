class PushWorkOrderArrivingJob
  include Unicorn::Notifications

  @queue = :high

  class << self
    def perform(work_order_id)
      new(work_order_id).process
    end
  end

  def initialize(work_order_id)
    @work_order_id = work_order_id
  end

  def process
    send_push_notifications
  end

  private

  def users
    @users ||= work_order.user ? [work_order.user] : []
  end

  def mobile_notification_params
    params = {
        work_order_id: @work_order_id,
    }
    params.merge!({
      alert: {
        title: 'Your driver is arriving.',
        body: 'Tap for details.',
      },
      sound: 'default',
    })
    params
  end

  def work_order
    @work_order ||= WorkOrder.unscoped.find(@work_order_id) rescue nil
  end
end
