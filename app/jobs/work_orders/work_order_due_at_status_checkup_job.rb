class WorkOrderDueAtStatusCheckupJob
  @queue = :high

  class << self
    def perform(work_order_id)
      work_order = WorkOrder.unscoped.find(work_order_id) rescue nil
      return unless work_order

      case work_order.status.to_sym
        when :delayed
          work_order.abandon!
        else
          # no-op for now
      end
    end
  end
end
