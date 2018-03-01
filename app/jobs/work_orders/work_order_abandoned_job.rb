class WorkOrderAbandonedJob
  @queue = :high

  class << self
    def perform(work_order_id)
      work_order = WorkOrder.unscoped.find(work_order_id) rescue nil
      return unless work_order

      has_contact_email = work_order.company.try(:contact).try(:email)
      Resque.enqueue(WorkOrderEmailJob, work_order.id, :customer_service_notification) if has_contact_email

      unless !work_order.customer_communications_enabled? || work_order.customer_communications_config[:email_upon_abandoned_follow_up_offset].nil?
        enqueue_at = work_order.abandoned_at + work_order.customer_communications_config[:email_upon_abandoned_follow_up_offset].seconds
        Resque.enqueue_at(enqueue_at, WorkOrderEmailJob, work_order.id, :upon_abandoned_follow_up)
      end
    end
  end
end
