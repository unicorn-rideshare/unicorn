class WorkOrderConfirmationStatusCheckupJob
  @queue = :high

  class << self
    def perform(work_order_id)
      work_order = WorkOrder.unscoped.find(work_order_id) rescue nil
      return unless work_order

      case work_order.status.to_sym
      when :pending_acceptance
        work_order.timeout!
      end
    end
  end
end
