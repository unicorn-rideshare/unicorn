class RouteLeg < ActiveRecord::Base

  belongs_to :route
  has_one :work_order
  validates_presence_of :work_order

  before_validation :validate_work_order

  default_scope { order('id') }

  attr_accessor :work_order_was

  def can_schedule?
    work_order && [:awaiting_schedule, :abandoned].include?(work_order.status.to_s.to_sym)
  end

  def can_start?
    work_order && [:scheduled].include?(work_order.status.to_s.to_sym)
  end

  def work_order=(work_order)
    @work_order_was = self.work_order
    super(work_order)
  end

  private

  def valid_work_order_transition?
    work_order_was.nil? || [:awaiting_schedule, :scheduled].include?(work_order_was.status.to_sym)
  end

  def validate_work_order
    errors.add(:work_order, I18n.t('errors.messages.route_leg_work_order_must_not_change_once_started')) unless valid_work_order_transition?
  end
end
