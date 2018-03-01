class WorkOrderCompletedJob
  @queue = :high

  class << self
    def perform(work_order_id)
      work_order = WorkOrder.unscoped.find(work_order_id) rescue nil
      return unless work_order

      Resque.enqueue(WorkOrderEmailJob, work_order.id, :customer_service_notification) if work_order.items_rejected.count > 0 && work_order.company.contact.email
      Resque.enqueue(WorkOrderEmailJob, work_order.id, :receipt) if work_order.user

      unless !work_order.customer_communications_enabled? || work_order.customer_communications_config[:email_upon_completion_follow_up_offset].nil?
        enqueue_at = work_order.ended_at + work_order.customer_communications_config[:email_upon_completion_follow_up_offset].seconds
        Resque.enqueue_at(enqueue_at, WorkOrderEmailJob, work_order.id, :upon_completion_follow_up)
      end
    end
  end
end
