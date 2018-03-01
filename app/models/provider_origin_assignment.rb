class ProviderOriginAssignment < ActiveRecord::Base
  include StateMachine

  resourcify

  belongs_to :provider
  validates :provider, presence: true
  validates :provider_id, readonly: true, on: :update
  validate :provider_must_be_unique_in_effective_date_range

  belongs_to :origin, inverse_of: :provider_origin_assignments
  validates :origin, presence: true
  validates :origin_id, readonly: true, on: :update
  validate :origin_market_must_belong_to_provider_company

  validate :valid_effective_date_range

  validate :valid_scheduled_start_at, if: :scheduled_start_at_changed?

  has_many :routes

  after_create :setup_permissions

  aasm column: :status, whiny_transitions: false do
    state :scheduled, initial: true
    state :canceled
    state :completed
    state :in_progress

    event :scheduled do
      before do
        self.scheduled_start_at = self.start_date.midnight if self.start_date && self.scheduled_start_at.nil?
      end
    end

    event :cancel do
      transitions from: :scheduled, to: :canceled

      before do
        self.canceled_at = DateTime.now
      end
    end

    event :clock_in do
      transitions from: :scheduled, to: :in_progress

      before do
        self.started_at = DateTime.now
      end
    end

    event :clock_out do
      transitions from: :in_progress, to: :completed

      before do
        self.ended_at = DateTime.now
        self.duration = self.ended_at.to_i - self.started_at.to_i
      end
    end
  end

  scope :on_date, ->(date) {
    query = <<-EOS
      provider_origin_assignments.status IN ('scheduled', 'in_progress')
      AND (provider_origin_assignments.start_date = :date AND provider_origin_assignments.end_date = :date)
    EOS

    where(query, date: date).order('provider_origin_assignments.scheduled_start_at ASC')
  }

  scope :in_effect, ->(date, allow_indefinite = false) {
    query = <<-EOS
      provider_origin_assignments.status IN ('scheduled', 'in_progress')
      AND (provider_origin_assignments.start_date <= :date AND provider_origin_assignments.end_date >= :date)
    EOS

    indefinite_query = <<-EOS
      OR (provider_origin_assignments.start_date IS NULL AND provider_origin_assignments.end_date IS NULL)
      OR (provider_origin_assignments.start_date <= :date AND provider_origin_assignments.end_date IS NULL)
    EOS
    query += indefinite_query if allow_indefinite

    where(query, date: date).order('provider_origin_assignments.scheduled_start_at ASC')
  }

  def company_id
    return nil unless provider
    provider.company_id
  end

  def completed_routes?
    routes.reload.each do |route|
      return false unless route.disposed?
    end
    true
  end

  def single_day?
    start_date && end_date && start_date == end_date
  end

  private

  def origin_market_must_belong_to_provider_company
    return unless provider_id && origin_id
    match = provider.company_id == origin.market.company_id
    errors.add(:base, :origin_market_provider_company_confirmation) unless match
  end

  def provider_must_be_unique_in_effective_date_range
    return unless provider_id && origin_id
    date = end_date || start_date
    effective_assignments = provider.origin_assignments.where(origin_id: origin_id)
    effective_assignments = effective_assignments.in_effect(date) if date
    unique_in_effective_date_range = effective_assignments.reject { |assignment| assignment == self }.size == 0
    errors.add(:base, :origin_assignment_indefinite) unless unique_in_effective_date_range
  end

  def setup_permissions
    self.provider.user.add_role(:provider, self) if self.provider && self.provider.user
  end

  def valid_scheduled_start_at
    errors.add(:scheduled_start_at, I18n.t('errors.messages.must_not_be_in_past')) if scheduled_start_at && scheduled_start_at < DateTime.now
  end

  def valid_effective_date_range
    valid_date_range = self.start_date && self.end_date && self.start_date <= self.end_date
    errors.add(:base, :origin_assignment_effective_date_range) unless valid_date_range
  end
end
