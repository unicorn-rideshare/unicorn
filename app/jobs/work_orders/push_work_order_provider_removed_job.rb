class PushWorkOrderProviderRemovedJob
  include Unicorn::Notifications

  @queue = :high

  class << self
    def perform(work_order_id, provider_id)
      new(work_order_id, provider_id).process
    end
  end

  def initialize(work_order_id, provider_id)
    @work_order_id = work_order_id
    @provider_id = provider_id
  end

  def process
    send_push_notifications
  end

  private

  def provider
    @provider ||= Provider.find(@provider_id)
  end

  def users
    @users ||= provider && provider.user ? [provider.user] : []
  end

  def mobile_notification_params
    {
        work_order_id: @work_order_id,
        provider_id: @provider_id,
        provider_removed: true
    }
  end

  def work_order
    @work_order ||= WorkOrder.unscoped.find(@work_order_id) rescue nil
  end
end
