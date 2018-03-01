class DispatcherOriginAssignment < ActiveRecord::Base

  resourcify

  belongs_to :dispatcher
  validates :dispatcher, presence: true
  validates :dispatcher_id, readonly: true, on: :update
  validate :dispatcher_must_be_unique_in_effective_date_range

  belongs_to :origin, inverse_of: :dispatcher_origin_assignments
  validates :origin, presence: true
  validates :origin_id, readonly: true, on: :update
  validate :origin_market_must_belong_to_dispatcher_company

  validate :valid_effective_date_range

  has_many :routes

  after_create :setup_permissions

  scope :on_date, ->(date) {
    query = <<-EOS
      dispatcher_origin_assignments.start_date = :date AND dispatcher_origin_assignments.end_date = :date
    EOS

    where(query, date: date).order('dispatcher_origin_assignments.scheduled_start_at ASC')
  }

  scope :in_effect, ->(date, allow_indefinite = false) {
    query = <<-EOS
      (dispatcher_origin_assignments.start_date <= :date AND dispatcher_origin_assignments.end_date >= :date)
    EOS

    indefinite_query = <<-EOS
      OR (dispatcher_origin_assignments.start_date IS NULL AND dispatcher_origin_assignments.end_date IS NULL)
      OR (dispatcher_origin_assignments.start_date <= :date AND dispatcher_origin_assignments.end_date IS NULL)
    EOS
    query += indefinite_query if allow_indefinite

    where(query, date: date).order('dispatcher_origin_assignments.scheduled_start_at ASC')
  }

  def company_id
    return nil unless dispatcher
    dispatcher.company_id
  end

  private

  def dispatcher_must_be_unique_in_effective_date_range
    return unless dispatcher_id && origin_id
    date = end_date || start_date
    effective_assignments = dispatcher.origin_assignments.where(origin_id: origin_id)
    effective_assignments = effective_assignments.in_effect(date) if date
    unique_in_effective_date_range = effective_assignments.reject { |assignment| assignment == self }.size == 0
    errors.add(:base, :origin_assignment_indefinite) unless unique_in_effective_date_range
  end

  def origin_market_must_belong_to_dispatcher_company
    return unless dispatcher_id && origin_id
    match = dispatcher.company_id == origin.market.company_id
    errors.add(:base, :origin_market_dispatcher_company_confirmation) unless match
  end

  def setup_permissions
    self.dispatcher.user.add_role(:dispatcher, self) if self.dispatcher && self.dispatcher.user
  end

  def valid_effective_date_range
    valid_date_range = self.start_date && self.end_date && self.start_date <= self.end_date
    errors.add(:base, :origin_assignment_effective_date_range) unless valid_date_range
  end
end
