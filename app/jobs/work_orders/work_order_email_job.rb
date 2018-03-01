class WorkOrderEmailJob
  @queue = :high

  class << self
    def perform(work_order_id, mail_message)
      work_order = WorkOrder.unscoped.find(work_order_id) rescue nil
      return unless work_order

      WorkOrderMailer.send("deliver_#{mail_message.to_s.downcase.to_sym}", work_order)
    end
  end
end
