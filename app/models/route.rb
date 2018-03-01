class Route < ActiveRecord::Base
  include Notifiable
  include StateMachine

  resourcify

  belongs_to :company
  validates :company, presence: true
  validates :company_id, readonly: true, on: :update

  belongs_to :dispatcher_origin_assignment
  # validates :dispatcher_origin_assignment, presence: true
  # validates :dispatcher_origin_assignment_id, readonly: true, on: :update

  belongs_to :provider_origin_assignment
  # validates :provider_origin_assignment, presence: true
  # validates :provider_origin_assignment_id, readonly: true, on: :update

  has_many :legs, class_name: RouteLeg.name
  has_many :work_orders, through: :legs

  has_and_belongs_to_many :items_loaded, class_name: Product.name, join_table: :loaded_products_routes

  has_many :items_delivered, through: :work_orders
  has_many :items_ordered, through: :work_orders
  has_many :items_rejected, through: :work_orders

  validates_presence_of :date
  validate :date_is_valid_for_dispatcher_origin_assignment
  validate :date_is_valid_for_provider_origin_assignment

  validates_presence_of :dispatcher_origin_assignment
  validates_presence_of :provider_origin_assignment

  validate :company_must_match_origin_assignments

  after_create :setup_permissions

  aasm column: :status, whiny_transitions: false do
    state :awaiting_schedule, initial: true
    state :canceled
    state :scheduled
    state :loading
    state :in_progress
    state :unloading
    state :pending_completion
    state :completed

    event :schedule do
      transitions from: [:awaiting_schedule, :scheduled], to: :scheduled, guard: :scheduled_start_at_changed?

      after do
        Resque.enqueue(RouteScheduledJob, self.id)
      end
    end

    event :cancel do
      transitions from: [:awaiting_schedule, :scheduled], to: :canceled

      after do
        Resque.enqueue(RouteCanceledJob, self.id)
      end
    end

    event :load do
      transitions from: :scheduled, to: :loading

      before do
        self.loading_started_at = DateTime.now
        self.provider_origin_assignment.clock_in! unless self.provider_origin_assignment.in_progress?
      end
    end

    event :start do
      transitions from: [:scheduled, :loading], to: :in_progress, guard: :can_start?

      before do
        timestamp = DateTime.now
        self.started_at = timestamp

        if self.status.to_sym == :loading
          self.loading_ended_at = timestamp
          self.loading_duration = self.loading_ended_at.to_i - self.loading_started_at.to_i
        end
      end
    end

    event :unload do
      transitions from: :in_progress, to: :unloading

      before do
        self.unloading_started_at = DateTime.now
      end
    end

    event :close do
      transitions from: [:in_progress, :unloading], to: :pending_completion

      before do
        if self.status.to_sym == :unloading
          self.unloading_ended_at = DateTime.now
          self.unloading_duration = self.unloading_ended_at.to_i - self.unloading_started_at.to_i
        end
      end

      after do
        self.provider_origin_assignment.clock_out! if self.provider_origin_assignment.in_progress? && self.provider_origin_assignment.completed_routes?
      end
    end

    event :complete do
      transitions from: [:in_progress, :unloading, :pending_completion], to: :completed

      before do
        self.ended_at = DateTime.now
        self.duration = self.ended_at.to_i - self.started_at.to_i
      end
    end
  end

  default_scope { order('routes.scheduled_start_at ASC') }

  scope :greedy, ->() {
    includes(:items_loaded, :legs, :dispatcher_origin_assignment, :provider_origin_assignment)
  }

  scope :ordered_by_started_at_desc, -> {
    unscope(:order).order('routes.date DESC, routes.started_at DESC')
  }

  scope :requiring_provider_action, -> {
    query = <<-EOS
      routes.status NOT IN ('canceled', 'pending_completion', 'completed')
    EOS

    where(query)
  }

  def checkin_coordinates
    starting_at = self.started_at
    ending_at = self.unloading_ended_at || self.ended_at
    return [] if starting_at.nil? || provider.nil? || provider.user.nil?

    provider.user.interpolated_checkin_coordinates(starting_at, ending_at)
  end

  def dispatcher
    dispatcher_origin_assignment.dispatcher if dispatcher_origin_assignment
  end

  def disposed?
    [
        :canceled,
        :pending_completion,
        :completed
    ].include?(self.status.to_s.to_sym)
  end

  def driving_duration
    driving_duration = 0
    work_orders.each do |work_order|
      driving_duration += work_order.driving_duration_hours
    end
    work_order_driving_ended_at = work_orders.last.driving_ended_at
    driving_duration += ((unloading_started_at - work_order_driving_ended_at) / 3600) if unloading_started_at && work_order_driving_ended_at
    driving_duration
  end

  def incomplete_manifest?
    gtins_ordered.sort != (gtins_loaded + gtins_delivered).sort
  end

  def manifest_requires_gtin?(gtin)
    gtins_not_loaded.include?(gtin)
  end

  def provider
    provider_origin_assignment.provider if provider_origin_assignment
  end

  private

  def can_start?
    !incomplete_manifest?
  end

  def company_must_match_origin_assignments
    return unless company_id && dispatcher_origin_assignment_id && provider_origin_assignment_id
    errors.add(:base, :dispatcher_company_must_match_company) unless company_id == dispatcher_origin_assignment.company_id
    errors.add(:base, :provider_company_must_match_company) unless company_id == provider_origin_assignment.company_id
  end

  def date_is_valid_for_dispatcher_origin_assignment
    return unless date && dispatcher_origin_assignment
    valid_for_start_date = dispatcher_origin_assignment.start_date ? date >= dispatcher_origin_assignment.start_date.to_date : true
    valid_for_end_date = dispatcher_origin_assignment.end_date ? date <= dispatcher_origin_assignment.end_date.to_date : true
    errors.add(:base, :route_date_must_be_valid_for_dispatcher_origin_assignment) unless valid_for_start_date && valid_for_end_date
  end

  def date_is_valid_for_provider_origin_assignment
    return unless date && provider_origin_assignment
    valid_for_start_date = provider_origin_assignment.start_date ? date >= provider_origin_assignment.start_date.to_date : true
    valid_for_end_date = provider_origin_assignment.end_date ? date <= provider_origin_assignment.end_date.to_date : true
    errors.add(:base, :route_date_must_be_valid_for_provider_origin_assignment) unless valid_for_start_date && valid_for_end_date
  end

  def gtins_delivered
    items_delivered.map(&:gtin)
  end

  def gtins_loaded
    items_loaded.map(&:gtin)
  end

  def gtins_not_loaded
    counts = (gtins_loaded + gtins_delivered).inject(Hash.new(0)) { |h, v| h[v] += 1; h }
    gtins_ordered.reject { |v| counts[v] -= 1 unless counts[v].zero? }
  end

  def gtins_ordered
    items_ordered.map(&:gtin)
  end

  def gtins_rejected
    items_rejected.map(&:gtin)
  end

  def notification_params(notification_type)
    {
        include_work_orders: true,
        include_checkin_coordinates: true,
        include_products: true,
        include_dispatcher_origin_assignment: true,
        include_provider_origin_assignment: true
    }
  end

  def notification_recipients(notification_type)
    recipients = []

    provider = self.provider_origin_assignment.provider if self.provider_origin_assignment
    dispatcher = self.dispatcher_origin_assignment.dispatcher if self.dispatcher_origin_assignment

    self.company.admins.map { |user| recipients << user }

    recipients << provider.user if provider && provider.user
    recipients << dispatcher.user if dispatcher && dispatcher.user

    recipients
  end

  def setup_permissions
    if dispatcher_origin_assignment
      dispatcher = dispatcher_origin_assignment.dispatcher
      dispatcher.user.add_role(:dispatcher, self) if dispatcher && dispatcher.user
    end

    if provider_origin_assignment
      provider = provider_origin_assignment.provider
      provider.user.add_role(:provider, self) if provider && provider.user
    end
  end
end
