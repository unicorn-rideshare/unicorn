class WorkOrderStartedStatusCheckupJob
  @queue = :high

  class << self
    def perform(work_order_id)
      work_order = WorkOrder.unscoped.find(work_order_id) rescue nil
      return unless work_order

      Resque.remove_delayed(WorkOrderDueAtStatusCheckupJob, work_order.id)

      case work_order.status.to_sym
        when :scheduled
          work_order.abandon! unless work_order.due_at
          work_order.delay! if work_order.due_at
        else
          # no-op for now
      end
    end
  end
end
