class WorkOrderScheduledJob
  @queue = :high

  class << self
    def perform(work_order_id)
      work_order = WorkOrder.unscoped.find(work_order_id) rescue nil
      return unless work_order

      %w(scheduled_confirmation reminder morning_of_reminder).each do |mail_message|
        Resque.remove_delayed(WorkOrderEmailJob, work_order.id, mail_message.to_sym)
      end

      Resque.remove_delayed(WorkOrderStartedStatusCheckupJob, work_order.id)

      unless work_order.scheduled_start_at.nil?
        %w(scheduled_confirmation reminder).each do |mail_message|
          config_key = "email_#{mail_message}_offset".to_sym
          unless !work_order.customer_communications_enabled? || work_order.customer_communications_config[config_key].nil?
            enqueue_at = work_order.scheduled_start_at + work_order.customer_communications_config[config_key].seconds
            Resque.enqueue_at(enqueue_at, WorkOrderEmailJob, work_order.id, mail_message.to_sym)
          end
        end

        unless !work_order.customer_communications_enabled? || work_order.customer_communications_config[:email_morning_of_reminder_offset].nil?
          enqueue_at = work_order.scheduled_start_at.midnight + work_order.customer_communications_config[:email_morning_of_reminder_offset].seconds
          Resque.enqueue_at(enqueue_at, WorkOrderEmailJob, work_order.id, :morning_of_reminder)
        end

        Resque.enqueue_at(work_order.scheduled_start_at, WorkOrderStartedStatusCheckupJob, work_order.id)
      end
    end
  end
end
