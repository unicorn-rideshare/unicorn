class WorkOrderDelayedJob
  @queue = :high

  class << self
    def perform(work_order_id)
      work_order = WorkOrder.unscoped.find(work_order_id) rescue nil
      return unless work_order

      has_contact_email = work_order.company.try(:contact).try(:email)
      Resque.enqueue(WorkOrderEmailJob, work_order.id, :due_date_escalation) if has_contact_email

      Resque.enqueue_at(work_order.due_at, WorkOrderDueAtStatusCheckupJob, work_order.id)
    end
  end
end
