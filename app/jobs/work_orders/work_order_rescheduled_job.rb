class WorkOrderRescheduledJob
  @queue = :high

  class << self
    def perform(work_order_id)
      work_order = WorkOrder.unscoped.find(work_order_id) rescue nil
      return unless work_order

      %w(scheduled_confirmation reminder morning_of_reminder).each do |mail_message|
        Resque.remove_delayed(WorkOrderEmailJob, work_order.id, mail_message.to_sym)
      end

      Resque.remove_delayed(WorkOrderStartedStatusCheckupJob, work_order.id)
      Resque.enqueue_at(work_order.scheduled_start_at, WorkOrderStartedStatusCheckupJob, work_order.id) unless work_order.scheduled_start_at.nil?
    end
  end
end
