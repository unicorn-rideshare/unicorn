class Origin < ActiveRecord::Base
  include Contactable

  belongs_to :market
  validates :market, presence: true

  has_many :dispatcher_origin_assignments
  has_many :dispatchers, through: :dispatcher_origin_assignments

  has_many :provider_origin_assignments
  has_many :providers, through: :provider_origin_assignments

  has_many :work_orders

  def available_dispatcher_origin_assignments(date = Date.today)
    available_dispatcher_origin_assignments = []
    dispatcher_origin_assignments.on_date(date).each do |dispatcher_origin_assignments|
      available_dispatcher_origin_assignments << dispatcher_origin_assignments if dispatcher_origin_assignments.dispatcher.routes.where('DATE(routes.scheduled_start_at) = :date', date: date).count == 0
    end
    available_dispatcher_origin_assignments
  end

  def available_provider_origin_assignments(date = Date.today)
    available_provider_origin_assignments = []
    provider_origin_assignments.on_date(date).each do |provider_origin_assignment|
      available_provider_origin_assignments << provider_origin_assignment if provider_origin_assignment.provider.routes.requiring_provider_action.where('DATE(routes.scheduled_start_at) = :date', date: date).count == 0 # TODO: refine this down to hourly timestamp
    end
    available_provider_origin_assignments
  end

  def require_contact_time_zone?
    true
  end
end
