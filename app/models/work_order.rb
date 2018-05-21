class WorkOrder < ActiveRecord::Base
  include Attachable
  include Commentable
  include Expensable
  include Notifiable
  include StateMachine
  include WorkOrderSettings

  resourcify

  belongs_to :company
  validates :company_id, readonly: true, on: :update

  belongs_to :category
  validates :category_id, readonly: true, on: :update, unless: :on_demand?
  validate :category_company_must_match

  belongs_to :customer
  validates :customer_id, readonly: true, on: :update
  validate :customers_company_must_match

  belongs_to :user
  validates :user_id, readonly: true, on: :update

  belongs_to :origin
  validate :origin_market_must_belong_to_company

  belongs_to :route_leg

  has_many :tasks

  has_and_belongs_to_many :items_delivered, class_name: Product.name, join_table: :delivered_products_work_orders
  has_and_belongs_to_many :items_ordered, class_name: Product.name, join_table: :ordered_products_work_orders
  has_and_belongs_to_many :items_rejected, class_name: Product.name, join_table: :rejected_products_work_orders

  belongs_to :job

  has_many :work_order_products
  accepts_nested_attributes_for :work_order_products

  has_many :work_order_providers, inverse_of: :work_order
  accepts_nested_attributes_for :work_order_providers

  validates :customer_rating, inclusion: { in: 0..10 }, allow_nil: true, numericality: { only_integer: true }

  validate :due_at_cannot_be_in_the_past_or_prior_to_scheduled_start_at, if: :due_at_changed?

  validates_numericality_of :estimated_distance, greater_than_or_equal_to: 0, allow_nil: true
  validates_numericality_of :estimated_duration, greater_than_or_equal_to: 0, allow_nil: true

  validate :preferred_scheduled_start_date_cannot_be_in_the_past, if: :preferred_scheduled_start_date_changed?
  validate :preferred_scheduled_start_date_required, if: lambda { self.status.to_sym == :awaiting_schedule && self.job_id.nil? && self.company_id.present? }

  validate :scheduled_start_at_cannot_be_in_the_past, if: :scheduled_start_at_changed?
  validate :scheduled_start_at_cannot_be_double_booked

  validate :items_delivered_must_be_items_ordered
  validate :items_rejected_must_be_items_ordered
  validate :items_delivered_and_rejected_must_match_items_ordered

  validate :priority_is_valid

  validates :provider_rating, inclusion: { in: 0..10 }, allow_nil: true, numericality: { only_integer: true }

  before_validation :calculate_scheduled_end_at, unless: lambda { self.estimated_duration.nil? }

  before_create :calculate_estimates

  after_create :broadcast_tx, :setup_initial_providers

  after_save :read_work_order_provider_ids,
             :read_work_order_job_product_ids,
             :initialize_configured_components

  after_destroy :clear_supervisors,
                :clear_designated_approvers,
                :clear_final_approvers,
                :clear_watchers

  default_scope { order('work_orders.scheduled_start_at ASC NULLS LAST') }

  scope :greedy, ->() {
    includes(:category, :customer, :expenses, :items_delivered, :items_ordered, :items_rejected, :job, :work_order_products, :work_order_providers, :user)
  }

  scope :deferred_scheduling_due, lambda { |date|
    awaiting_schedule.on_preferred_scheduled_start_date(date)
  }

  scope :ordered_by_priority_and_due_at_asc, -> {
    unscope(:order).order('work_orders.priority DESC NULLS LAST, work_orders.due_at ASC NULLS LAST, work_orders.scheduled_start_at ASC NULLS FIRST')
  }

  scope :ordered_by_started_at_desc, -> {
    unscope(:order).order('work_orders.started_at DESC NULLS LAST, work_orders.scheduled_start_at DESC NULLS LAST')
  }

  scope :on, lambda { |date|
    query = <<-EOS
      (DATE(work_orders.scheduled_start_at) = :date)
    EOS
    where(query, date: date)
  }

  scope :on_or_before, lambda { |date|
    query = <<-EOS
      (DATE(work_orders.scheduled_start_at) <= :date)
    EOS
    where(query, date: date)
  }

  scope :on_or_after, lambda { |date|
    query = <<-EOS
      (DATE(work_orders.scheduled_start_at) >= :date)
    EOS
    where(query, date: date)
  }

  scope :before_inclusive, lambda { |date|
    query = <<-EOS
      (work_orders.scheduled_start_at <= :date)
    EOS
    where(query, date: date)
  }

  scope :after_inclusive, lambda { |date|
    query = <<-EOS
      (work_orders.scheduled_start_at >= :date)
    EOS
    where(query, date: date)
  }

  scope :user_location_subscriber, -> {
    where('work_orders.status IN (\'en_route\', \'arriving\', \'in_progress\')')
  }

  scope :in_date_range, lambda { |range|
    start_at = range.is_a?(Range) ? range.first : (range.is_a?(DateTime) ? range : nil)
    end_at = range.last if range.is_a?(Range)
    return all unless start_at && end_at
    return on(start_at.to_date) if start_at && end_at.nil?
    query = <<-EOS
      (work_orders.scheduled_start_at <= :start_at AND :start_at < work_orders.scheduled_end_at)
      OR (work_orders.scheduled_start_at < :end_at AND :end_at <= work_orders.scheduled_end_at)
      OR (:start_at <= work_orders.scheduled_start_at AND work_orders.scheduled_start_at < :end_at)
      OR (:start_at < work_orders.scheduled_end_at AND work_orders.scheduled_end_at <= :end_at)
    EOS
    where(query, start_at: range.first, end_at: range.last)
  }

  scope :on_preferred_scheduled_start_date, lambda { |preferred_scheduled_start_date|
    query = <<-EOS
      preferred_scheduled_start_date = :preferred_scheduled_start_date
    EOS
    where(query, preferred_scheduled_start_date: preferred_scheduled_start_date).order('preferred_scheduled_start_date ASC')
  }

  scope :ordered_by_distance_from_coordinate, lambda { |coordinate|
    select_stmt = "work_orders.*, contacts.geom, ST_Distance(ST_Transform(contacts.geom, 26986), ST_Transform(ST_SetSRID(ST_MakePoint(#{coordinate.longitude}, #{coordinate.latitude}), 4326), 26986)) AS estimated_meters_from_origin"

    join_clause = <<-EOS
      LEFT OUTER JOIN contacts ON contacts.contactable_id = work_orders.customer_id
    EOS

    where_clause = <<-EOS
      contacts.contactable_type = 'Customer'
    EOS

    order_by_clause = <<-EOS
      contacts.geom <-> ST_SetSRID(ST_MakePoint(#{coordinate.longitude}, #{coordinate.latitude}), 4326)
    EOS

    unscope(:order).select(select_stmt).joins(join_clause).where(where_clause).order(order_by_clause)
  }

  scope :by_provider_id, ->(provider_id) {
    joins('LEFT OUTER JOIN work_order_providers ON work_order_providers.work_order_id = work_orders.id').where('work_order_providers.provider_id = ?', provider_id)
  }

  aasm column: :status, whiny_transitions: false do
    state :abandoned
    state :awaiting_schedule, initial: true
    state :pending_acceptance
    state :scheduled
    state :canceled
    state :completed
    state :delayed
    state :en_route
    state :arriving
    state :in_progress
    state :paused
    state :pending_approval
    state :pending_final_approval
    state :rejected
    state :timed_out

    event :schedule do
      transitions from: [:awaiting_schedule, :scheduled, :delayed], to: :scheduled, guard: :scheduled_start_at_changed?

      after do
        Resque.enqueue(WorkOrderScheduledJob, self.id)
      end
    end

    event :confirm do  # this confirmation is set by a user who has created a workorder and an offer is made to providers
      transitions from: [:awaiting_schedule, :timed_out], to: :pending_acceptance

      after do
        timeout_at = DateTime.now + 20.seconds  # FIXME-- make timeout configuration item

        cfg = self.config.with_indifferent_access
        cfg['timeout_at'] = timeout_at.iso8601
        update_config(cfg)

        Resque.enqueue(WorkOrderConfirmedJob, self.id)
        Resque.enqueue_at(timeout_at, WorkOrderConfirmationStatusCheckupJob, self.id)
      end
    end

    event :timeout do
      transitions from: [:pending_acceptance], to: :timed_out

      after do
        self.work_order_providers.not_timed_out.each do |work_order_provider|
          work_order_provider.update_attribute(:timed_out_at, DateTime.now) if work_order_provider.timed_out_at.nil?
        end

        self.confirm!
      end
    end

    event :delay do
      transitions from: [:scheduled], to: :delayed, guard: :pending_delay?

      after do
        Resque.enqueue(WorkOrderDelayedJob, self.id)
      end
    end

    event :abandon do
      transitions from: [:scheduled, :delayed, :en_route, :in_progress, :paused], to: :abandoned

      before do
        self.abandoned_at = DateTime.now
        self.waiting_duration = self.abandoned_at.to_i - (self.arrived_at? ? self.arrived_at.to_i : self.started_at.to_i)
      end

      after do
        Resque.enqueue(WorkOrderAbandonedJob, self.id)
      end
    end

    event :approve do
      transitions from: [:pending_approval], to: :completed

      before do
        self.approved_at = DateTime.now
        self.review_duration = (self.review_duration || 0).to_i + self.approved_at.to_i - self.submitted_for_approval_at.to_i
      end

      after do
        # TODO-- send notifications to approver
      end
    end

    event :cancel do
      transitions from: [:awaiting_schedule, :pending_acceptance, :scheduled, :delayed, :en_route, :arriving, :in_progress, :paused, :pending_approval], to: :canceled

      before do
        self.canceled_at = DateTime.now
      end

      after do
        Resque.remove_delayed(WorkOrderConfirmationStatusCheckupJob, self.id)
        %w(scheduled_confirmation reminder morning_of_reminder).map { |mail_message| Resque.remove_delayed(WorkOrderEmailJob, self.id, mail_message.to_sym) }
        Resque.enqueue(WorkOrderCanceledJob, self.id)
        Resque.enqueue(ExecuteWorkOrderContractJob, self.id, ENV['PROVIDE_APPLICATION_API_TOKEN'], "cancel", []) if self.eth_contract_address
      end
    end

    event :reject do
      transitions from: [:pending_approval], to: :rejected

      before do
        self.rejected_at = DateTime.now
        self.review_duration = (self.review_duration || 0).to_i + self.rejected_at.to_i - self.submitted_for_approval_at.to_i
      end

      after do
        # TODO-- send notifications to responsible provider(s) and other stakeholders
      end
    end

    event :route do
      transitions from: [:scheduled, :delayed, :pending_acceptance], to: :en_route

      before do
        if self.status.to_sym == :pending_acceptance
          self.accepted_at = DateTime.now

          peer = self.providers.first.user.wallets.last.address
          Resque.enqueue(ExecuteWorkOrderContractJob, self.id, ENV['PROVIDE_APPLICATION_API_TOKEN'], "start", [peer]) if self.eth_contract_address
        else
          self.started_at = DateTime.now
        end
      end

      after do
        Resque.remove_delayed(WorkOrderConfirmationStatusCheckupJob, self.id)
        Resque.enqueue(WorkOrderProviderEnRouteJob, self.id)
      end
    end

    event :arrive do
      transitions from: [:en_route], to: :arriving

      before do
        if self.status.to_sym == :en_route
          self.arrived_at = DateTime.now
          self.driving_duration = self.arrived_at.to_i - (self.accepted_at || self.started_at).to_i
        end
      end

      after do
        Resque.enqueue(PushWorkOrderArrivingJob, self.id)
      end
    end

    event :start do
      transitions from: [:scheduled, :delayed, :en_route, :arriving], to: :in_progress

      before do
        if self.status.to_sym == :en_route
          self.arrived_at = DateTime.now
          self.driving_duration = self.arrived_at.to_i - (self.accepted_at || self.started_at).to_i
        else
          self.started_at = DateTime.now
        end
      end
    end

    event :restart do
      transitions from: [:rejected], to: :in_progress

      before do
        self.started_at = DateTime.now
        self.ended_at = nil
      end
    end

    event :submit_for_approval do
      transitions from: [:in_progress], to: :pending_approval

      before do
        self.submitted_for_approval_at = DateTime.now
        work_duration_offset = self.rejected_at
        work_duration_offset ||= self.arrived_at? ? self.arrived_at : self.started_at
        self.work_duration = (self.work_duration || 0).to_i + self.submitted_for_approval_at.to_i - work_duration_offset.to_i
      end

      after do
        # TODO-- send notifications to approver
      end
    end

    event :pause do
      transitions from: :in_progress, to: :paused
    end

    event :resume do
      transitions from: :paused, to: :in_progress
    end

    event :complete do
      transitions from: [:in_progress, :paused], to: :completed

      before do
        self.ended_at = DateTime.now
        self.work_duration ||= self.ended_at.to_i - (self.arrived_at? ? self.arrived_at.to_i : self.started_at.to_i)
        self.driving_duration = (self.driving_duration || 0).to_i + self.work_duration.to_i
      end

      after do
        Resque.enqueue(WorkOrderCompletedJob, self.id)
        Resque.enqueue(ExecuteWorkOrderContractJob, self.id, ENV['PROVIDE_APPLICATION_API_TOKEN'], "complete", [0, "#{self.distance}"]) if self.eth_contract_address
      end
    end

    event :reschedule do
      transitions from: [:scheduled, :delayed, :canceled, :abandoned], to: :scheduled, guard: :pending_reschedule?

      before do
        self.abandoned_at = nil
      end

      after do
        Resque.enqueue(WorkOrderRescheduledJob, self.id)
      end
    end
  end

  [
      :supervisors,
      :designated_approvers,
      :final_approvers,
      :watchers
  ].each do |role|
    class_eval <<EOF, __FILE__, __LINE__ + 1
      def #{role}
        User.with_role(:#{role.to_s.singularize}, self)
      end

      def #{role}=(members)
        removed_members = self.#{role}.reject { |member| members.include?(member) }
        removed_members.each { |removed_member| removed_member.remove_role(:#{role.to_s.singularize}, self) }
        members.reject { |member| member.nil? || !member.is_a?(User) }.each { |member| member.add_role(:#{role.to_s.singularize}, self) }
      end

      def clear_#{role}
        #{role} = []
      end
EOF
  end

  def checkin_coordinates(provider = nil)
    provider ||= providers.first
    starting_at = self.started_at
    ending_at = self.ended_at || self.canceled_at || self.abandoned_at
    return [] if starting_at.nil? || provider.nil? || provider.user.nil?

    provider.user.interpolated_checkin_coordinates(starting_at, ending_at)
  end

  def dispatch_nearest_provider!
    # offer the work to the next closest provider
    # TODO-- use the work order config to further parameterize the provider search below (i.e. category/standalone not supported below)
    lat = config['origin']['latitude'] rescue nil
    lng = config['origin']['longitude'] rescue nil
    coord = Coordinate.new(lat, lng) rescue nil # FIXME-- update work order dynamically with user location as it changes
    radius = config['origin'].try('radius') || 10

    ineligible_provider_ids = work_order_providers.map(&:provider_id)
    next_provider = Provider.available_for_hire.active.nearby(coord, radius).where.not(id: ineligible_provider_ids).first

    work_order_providers.create(provider: next_provider) if next_provider
    provider_added(next_provider) if next_provider
  end

  def disposed?
    [
        :abandoned,
        :canceled,
        :completed
    ].include?(self.status.to_s.to_sym)
  end

  def customer_communications_config
    cfg = config[:customer_communications]
    cfg.delete_if { |key, value| value.nil? } if cfg
    (cfg ? customer.communications_config.merge(cfg) : customer.communications_config).with_indifferent_access
  end

  def customer_communications_enabled?
    cfg = config[:customer_communications]
    return cfg[:communications_enabled] if cfg && cfg[:communications_enabled]
    false
  end

  def driving_ended_at
    return DateTime.now if en_route?
    arrived_at || abandoned_at || canceled_at
  end

  def driving_duration_hours
    return driving_duration / 3600.0 if driving_duration
    driving_started_at = started_at
    return 0 unless driving_started_at && driving_ended_at
    (driving_ended_at - driving_started_at) / 3600.0
  end

  def duration
    return nil unless started_at && ended_at
    ended_at - started_at
  end

  def estimated_cost
    (estimated_providers_cost + materials_cost + expensed_amount).round(2)
  end

  def estimated_providers_cost
    work_order_providers.map(&:estimated_cost).reject { |estimated_cost| estimated_cost.nil? }.reduce(&:+).to_f
  end
  alias_method :labor_cost, :estimated_providers_cost

  def estimated_price(estimate_category = nil)
    return nil unless estimated_distance
    estimate_category ||= category
    return nil unless estimate_category
    base_price = estimate_category.base_price || 0.0
    price_per_mile = (estimate_category.price_per_mile || 0.0) rescue 0.0
    estimated_price_per_hour = (estimate_category.price_per_hour || 0.0) rescue 0.0
    (base_price + (estimated_distance.to_f * price_per_mile) + ((estimated_duration.to_f / 60.0) * estimated_price_per_hour)).to_f.round(2)
  end

  def expensed_amount
    expenses.map(&:amount).reject { |amount| amount.nil? }.reduce(&:+).to_f
  end

  def has_component?(component)
    return false unless config[:components]
    config[:components].select { |component_object| component_object[:component] == component }.size > 0
  end

  def on_demand?
    company_id.nil? && customer_id.nil? && scheduled_start_at.nil? && user_id.present?
  end

  def pending_delay?
    return false unless due_at
    scheduled? && scheduled_start_at < DateTime.now
  end

  def labor_revenue
    work_order_providers.map(&:estimated_revenue).reject { |estimated_revenue| estimated_revenue.nil? }.reduce(&:+).to_f
  end

  def materials
    work_order_products
  end

  def materials_cost
    materials.map(&:estimated_cost).reject { |estimated_cost| estimated_cost.nil? }.reduce(&:+).to_f
  end

  def provider_ids
    work_order_providers.map(&:provider_id)
  end

  def providers
    work_order_providers.map(&:provider)
  end

  def calculate_eta
    providers = work_order_providers.not_timed_out
    if providers.count == 1
      p = providers.first
      origin_coord = Coordinate.new(p.user.last_checkin_latitude, p.user.last_checkin_longitude)
      dest_coord = nil
      if status.match(/in_progress/i)
        dest_coord = Coordinate.new(self.config['destination']['latitude'], self.config['destination']['longitude']) rescue nil
      else
        lat = (self.config['current_location']['latitude'] rescue self.config['origin']['latitude']) rescue nil
        lng = (self.config['current_location']['longitude'] rescue self.config['origin']['longitude']) rescue nil
        dest_coord = Coordinate.new(lat, lng) rescue nil
      end
      estimates = (RoutingService.driving_estimates([origin_coord, dest_coord]) rescue nil) if dest_coord
      return {
        miles: (estimates['miles'] rescue nil),
        minutes: (estimates['minutes'] rescue nil),
      }
    end
    nil
  end

  def update_user_location(checkin)
    cfg = self.config
    cfg['current_location'] = {
      latitude: checkin.latitude,
      longitude: checkin.longitude,
      heading: checkin.heading,
      checkin_at: checkin.checkin_at.iso8601,
    }
    cfg['eta'] = calculate_eta

    self.config = cfg.with_indifferent_access
    self.save
  end

  def apply_broadcast_tx(latest_tx_result)
    cfg = self.config
    cfg['transactions'] ||= []
    cfg['transactions'] << latest_tx_result

    self.config = cfg.with_indifferent_access
    self.save
  end

  def work_order_products_attributes=(work_order_products_attributes)
    job_product_ids = []
    work_order_products_attributes.each do |attrs|
      job_product_id = attrs[:job_product_id] ? attrs[:job_product_id].to_i : attrs[:job_product_id]
      work_order_product = work_order_products.find(attrs[:id]) rescue work_order_products.where(job_product_id: job_product_id).first
      if work_order_product
        attrs[:id] = work_order_product.id unless attrs[:id]
        raise ArgumentError unless job_product_id == work_order_product.job_product_id
      end
      job_product_ids << job_product_id
    end

    read_work_order_job_product_ids unless @work_order_job_product_ids_was
    job_product_ids_was = @work_order_job_product_ids_was || []
    removed_work_order_product_ids = []

    job_product_ids_was.each do |job_product_id|
      work_order_product_id = work_order_products.select { |work_order_product| work_order_product.job_product_id == job_product_id }.first.id
      removed_work_order_product_ids << work_order_product_id unless job_product_ids.include?(job_product_id)
    end

    super(work_order_products_attributes)

    removed_work_order_product_ids.each do |removed_work_order_product_id|
      work_order_product = work_order_products.find(removed_work_order_product_id)
      work_order_product.destroy
    end
  end

  def work_order_providers_attributes=(work_order_providers_attributes)
    provider_ids = []
    work_order_providers_attributes.each do |attrs|
      provider_id = (attrs[:provider_id] ? attrs[:provider_id].to_i : (attrs[:provider][:id].to_i rescue nil)) rescue nil
      work_order_provider = work_order_providers.find(attrs[:id]) rescue work_order_providers.where(provider_id: provider_id).first
      if work_order_provider
        attrs[:id] = work_order_provider.id unless attrs[:id]
        raise ArgumentError unless provider_id == work_order_provider.provider_id
      end
      provider_ids << provider_id
    end

    read_work_order_provider_ids unless @work_order_provider_ids_was
    provider_ids_was = @work_order_provider_ids_was
    removed_work_order_provider_ids = []

    provider_ids_was.each do |provider_id|
      work_order_provider_id = work_order_providers.select { |work_order_provider| work_order_provider.provider_id == provider_id }.first.id
      removed_work_order_provider_ids << work_order_provider_id unless provider_ids.include?(provider_id)
    end

    # super(work_order_providers_attributes)

    provider_ids.each do |provider_id|
      unless provider_ids_was.include?(provider_id)
        _work_order_provider = work_order_providers.select { |work_order_provider| work_order_provider.provider_id == provider_id }.first
        if persisted?
          _work_order_provider = work_order_providers.create(provider_id: provider_id)
          provider_added(_work_order_provider.provider)
        else
          _work_order_provider = work_order_providers.build(provider_id: provider_id)
        end
      end
    end

    removed_work_order_provider_ids.each do |removed_work_order_provider_id|
      work_order_provider = work_order_providers.find(removed_work_order_provider_id)
      work_order_provider.destroy
      provider_removed(work_order_provider.provider)
    end
  end

  private

  def calculate_estimates  # FIXME-- this is not being done if the destination is changed
    cfg = self.config
    origin = cfg['origin']
    destination = cfg['destination']
    return unless origin && destination

    place_id = destination['place_id'] rescue nil
    if place_id
      # using google place details for destination
      place = RoutingService.place_details(place_id)
      if place
        geometry = place['geometry']
        origin_coord = Coordinate.new(origin['latitude'], origin['longitude'])
        dest_coord = Coordinate.new(geometry['location']['latitude'], geometry['location']['longitude'])
        estimates = RoutingService.driving_estimates([origin_coord, dest_coord])
        self.estimated_distance = estimates['miles']
        self.estimated_duration = estimates['minutes']

        place['latitude'] = geometry['location']['latitude']
        place['longitude'] = geometry['location']['longitude']

        %w(opening_hours adr_address reviews photos).each { |k| place.delete(k) rescue nil }
        cfg['destination'] = place

        cfg['eta'] = {
          miles: self.estimated_distance,
          minutes: self.estimated_duration,
        }

        cfg['overview'] = {
          shape: (estimates['shape'] rescue []),
          bounding_box: (estimates['bounding_box'] rescue nil),
        }

        coordinate = Coordinate.new(place['latitude'], place['longitude'])
        cfg['estimates_by_category'] = estimates_by_category(coordinate)

        self.config = cfg.with_indifferent_access
        self.save! if self.persisted?
      end
    end
  end

  def estimates_by_category(coordinate, radius = 50)
    estimates = []
    Category.nearby(coordinate, radius).each do |estimate_category|
      estimates << {
        category_id: estimate_category.id,
        price: estimated_price(estimate_category).try(:to_f),
      }
    end
    estimates
  end

  def calculate_scheduled_end_at
    self.scheduled_end_at = self.scheduled_start_at && self.scheduled_start_at + self.estimated_duration.minutes
  end

  def category_company_must_match
    return unless company_id && category_id
    self.category ||= Category.find(category_id) rescue nil
    return unless self.category
    match = self.category.company_id == company_id
    errors.add(:category_id, :work_order_category_must_match_company) unless match
  end

  def customers_company_must_match
    return unless company_id && customer_id
    match = customer.company_id == company_id
    errors.add(:customer_id, :work_order_company_confirmation) unless match
  end

  def due_at_cannot_be_in_the_past_or_prior_to_scheduled_start_at
    errors.add(:due_at, I18n.t('errors.messages.must_not_be_in_past')) if due_at && due_at < DateTime.now
    errors.add(:due_at, I18n.t('errors.messages.work_order_due_at_must_not_be_prior_to_scheduled_start_at')) if due_at && scheduled_start_at && due_at < scheduled_start_at
  end

  def notification_params(notification_type)
    {
        include_products: false,
        include_supervisors: false,
        include_work_order_providers: true,
        include_checkin_coordinates: false
    }
  end

  def notification_recipients(notification_type)
    recipients = self.work_order_providers.reload.map(&:user).reject { |user| user.nil? }
    self.company.admins.map { |user| recipients << user } rescue nil
    recipients << user if user
    recipients
  end

  def origin_market_must_belong_to_company
    return unless origin_id
    match = origin.market.company_id == company_id
    errors.add(:origin_id, :work_order_market_company_confirmation) unless match
  end

  def scheduled_start_at_cannot_be_in_the_past
    errors.add(:scheduled_start_at, I18n.t('errors.messages.must_not_be_in_past')) if scheduled_start_at && scheduled_start_at < DateTime.now
  end

  def scheduled_start_at_cannot_be_double_booked
    return unless scheduled_start_at && scheduled_end_at
    scheduled_work_orders = (company ? company.work_orders : WorkOrder.scheduled).in_date_range(scheduled_start_at..scheduled_end_at).includes(:work_order_providers)
    scheduled_work_orders = scheduled_work_orders.where('id != ?', id) if id
    scheduled_provider_ids = scheduled_work_orders.map(&:provider_ids).flatten
    provider_ids = work_order_providers.map(&:provider_id)
    errors.add(:scheduled_start_at, I18n.t('errors.messages.must_not_be_double_booked')) if (scheduled_provider_ids & provider_ids).present?
  end

  def preferred_scheduled_start_date_cannot_be_in_the_past
    errors.add(:preferred_scheduled_start_date, I18n.t('errors.messages.must_not_be_in_past')) if preferred_scheduled_start_date && preferred_scheduled_start_date < Date.today
  end

  def preferred_scheduled_start_date_required
    errors.add(:preferred_scheduled_start_date, I18n.t('errors.messages.must_not_be_null')) if preferred_scheduled_start_date.nil?
  end

  def initialize_configured_components
    cfg = config || {}
    return if cfg[:components] && cfg[:components].size > 0
    cfg[:components] ||= []
  end

  def items_ordered_counts
    items_ordered.map(&:gtin).inject(Hash.new(0)) { |h, v| h[v] += 1; h }
  end

  def items_delivered_counts
    items_delivered.map(&:gtin).inject(Hash.new(0)) { |h, v| h[v] += 1; h }
  end

  def items_rejected_counts
    items_rejected.map(&:gtin).inject(Hash.new(0)) { |h, v| h[v] += 1; h }
  end

  def items_delivered_and_rejected
    items_delivered + items_rejected
  end

  def items_delivered_must_be_items_ordered
    ordered_counts = items_ordered_counts
    items_delivered.each do |item|
      invalid_items_delivered = ordered_counts[item.gtin].nil?
      unless invalid_items_delivered
        errors.add(:items_delivered, I18n.t('errors.messages.items_delivered_must_be_items_ordered')) if ordered_counts[item.gtin] <= 0
        ordered_counts[item.gtin] -= 1
      end

    end
  end

  def items_rejected_must_be_items_ordered
    ordered_counts = items_ordered_counts
    items_rejected.each do |item|
      invalid_items_rejected = ordered_counts[item.gtin].nil?
      unless invalid_items_rejected
        errors.add(:items_rejected, I18n.t('errors.messages.items_rejected_must_be_items_ordered')) if ordered_counts[item.gtin] <= 0
        ordered_counts[item.gtin] -= 1
      end
    end
  end

  def items_delivered_and_rejected_must_match_items_ordered
    ordered_counts = items_ordered_counts
    items_delivered_and_rejected.each do |item|
      invalid_items_delivered_and_rejected = ordered_counts[item.gtin].nil?
      unless invalid_items_delivered_and_rejected
        errors.add(:items_delivered_and_rejected, I18n.t('errors.messages.items_delivered_and_rejected_must_match_items_ordered')) if ordered_counts[item.gtin] <= 0
        ordered_counts[item.gtin] -= 1
      end
    end
  end

  def pending_reschedule?
    scheduled_start_at_changed? || due_at_changed?
  end

  def read_work_order_job_product_ids
    @work_order_job_product_ids_was = work_order_products.map(&:job_product_id)
  end

  def read_work_order_provider_ids
    @work_order_provider_ids_was = work_order_providers.map(&:provider_id)
  end

  def broadcast_tx
    app_id = ENV['PROVIDE_APPLICATION_ID']
    wallet_id = ENV['PROVIDE_DEFAULT_APPLICATION_WALLET_ID']
    wo_contract_id = ENV['PROVIDE_DEFAULT_WORK_ORDER_CONTRACT_ID']
    jwt = ENV['PROVIDE_APPLICATION_API_TOKEN']
    peer_addr = self.user.wallets.last.address rescue nil
    return unless jwt && app_id && wallet_id && peer_addr
    status, resp = BlockchainService.execute_contract(jwt, wo_contract_id, { wallet_id: wallet_id, value: 0, method: 'createWorkOrder', params: [self.id] })
    tx = nil
    if status == 202
      tx = resp['transaction']
      self.apply_broadcast_tx(tx) if tx
      Resque.enqueue(FetchContractCreationAddressJob, self.id, tx['id']) if tx
    end
    return status, tx
  end

  def priority_is_valid
    errors.add(:priority, I18n.t('errors.messages.work_order_priority_invalid')) unless self.priority.nil? || self.priority.to_i > -1
  end

  def provider_added(provider)
    provider.user.add_role(:provider, self) if provider.user && persisted?
    provider.user.add_role(:provider, self.job) if provider.user && persisted? && self.job_id
    Resque.enqueue(PushWorkOrderProviderAddedJob, self.id, provider.id) if persisted?

    type = 'work_order_provider_added'
    slug = "#{type}_#{self.id}_#{self.object_id}_#{provider.id}"
    notification_recipients(:provider_added).each do |recipient|
      notifications.create(recipient: recipient,
                           type: type,
                           slug: slug,
                           params: notification_params(:provider_added)) rescue nil
    end
  end

  def provider_removed(provider)
    provider.user.remove_role(:provider, self) if provider.user
    provider.user.remove_role(:provider, self.job) if self.job_id && self.job.provider_work_orders(provider).size == 0
    Resque.enqueue(PushWorkOrderProviderRemovedJob, self.id, provider.id)

    type = 'work_order_provider_removed'
    slug = "#{type}_#{self.id}_#{self.object_id}_#{provider.id}"
    notification_recipients(:provider_removed).each do |recipient|
      notifications.create(recipient: recipient,
                           type: type,
                           slug: slug,
                           params: notification_params(:provider_removed)) rescue nil
    end
  end

  def setup_initial_providers
    work_order_providers.each do |_work_order_provider|
      provider_added(_work_order_provider.provider)
    end
  end
end
