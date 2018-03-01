class WorkOrderConfirmedJob
  @queue = :high

  class << self
    def perform(work_order_id)
      work_order = WorkOrder.unscoped.find(work_order_id) rescue nil
      return unless work_order

      work_order.dispatch_nearest_provider!
    end
  end
end
