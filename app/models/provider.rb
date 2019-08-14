class Provider < ActiveRecord::Base
  include Contactable

  attr_accessor :require_contact_time_zone

  belongs_to :company
  validates :company_id, readonly: true, on: :update

  has_many :origin_assignments, class_name: ProviderOriginAssignment.name
  has_many :routes, through: :origin_assignments

  belongs_to :user
  validates :user_id, uniqueness: { scope: :company_id }, allow_nil: true
  validates :user_id, readonly: true, on: :update

  has_and_belongs_to_many :categories

  has_many :tasks

  has_many :work_order_providers
  has_many :work_orders, through: :work_order_providers

  before_validation :require_user, on: :create

  after_create :setup_permissions

  after_save :dispatch_provider_availability_notifications

  before_destroy :cleanup_roles

  after_create :create_stripe_account

  after_destroy :destroy_stripe_account

  default_scope { order('id') }

  scope :active, ->(checkin_recency_in_minutes = 10) {  # TODO: add test coverage
    where('providers.last_checkin_at IS NOT NULL AND providers.last_checkin_at >= ?::timestamp - INTERVAL \'? minutes\'',
          DateTime.now.utc.to_s, checkin_recency_in_minutes)
  }

  scope :available_for_hire, -> {
    where('providers.available IS TRUE')
  }

  scope :unavailable_for_hire, -> {
    where('providers.available IS FALSE')
  }

  scope :nearby, ->(coordinate, radius_in_miles = 5) {  # TODO: add test coverage
    where('ST_DistanceSphere(providers.last_checkin_geom, ST_MakePoint(?, ?)) <= ?',
          coordinate.longitude, coordinate.latitude, radius_in_miles * 1609.34)
  }

  scope :by_category, ->(category_ids) {
    joins(:categories).where('categories.id = ?', category_ids)
  }

  scope :public_provider, -> {
    where('providers.publicly_available IS TRUE')
  }

  scope :standalone, -> {
    where('providers.company_id IS NULL')
  }

  scope :query, ->(query) {
    query_contacts_by_name(query)
  }

  def available_during?(start_at, end_at)
    work_orders.scheduled.in_date_range([start_at, end_at]).size == 0
  end

  def driving_duration(date = Date.today)
    driving_duration = 0
    work_orders.on(date).each do |work_order|
      driving_duration += work_order.driving_duration_hours
    end
    driving_duration
  end

  def last_checkin(since = DateTime.now - 10.minutes)  # FIXME-- denormalize last_checkin
    last_checkin = user.last_checkin if user
    return last_checkin unless since
    last_checkin if last_checkin && last_checkin.checkin_at >= since
  end

  def require_contact_time_zone?
    require_contact_time_zone.nil? ? true : require_contact_time_zone
  end

  def standalone?
    self.company_id.nil?
  end

  def create_stripe_bank_account(stripe_bank_account_token)
    return unless stripe_bank_account_token
    Resque.enqueue(CreateStripeBankAccountJob, Provider.name, self.id, stripe_bank_account_token)
  end

  def destroy_stripe_credit_card(stripe_bank_account_id)
    return unless stripe_bank_account_id
    Resque.enqueue(DestroyStripeBankAccountJob, Provider.name, self.id, stripe_bank_account_id)
  end

  private

  def stripe_account
    return nil unless self.stripe_account_id
    @stripe_account ||= begin
      Stripe::Account.retrieve(self.stripe_account_id) rescue nil
    end
  end

  def work_order_components
    config[:components]
  end

  private

  def create_stripe_account
    return if self.stripe_account_id
    Resque.enqueue(CreateStripeAccountJob, Provider.name, self.id)
  end

  def destroy_stripe_account
    return unless self.stripe_account_id
    Resque.enqueue(DestroyStripeAccountJob, self.stripe_account_id)
  end

  def cleanup_roles
    self.user.roles.reload.each do |role|
      resource = role.resource
      remove_role = resource && (resource.respond_to?(:company_id) && resource.company_id == self.company_id || resource == self.company)
      remove_role = resource.is_a?(ProviderOriginAssignment) && resource.origin.market.company_id == self.company_id unless remove_role
      self.user.remove_role(role.name.to_sym, resource) if remove_role
    end if self.user
  end

  def dispatch_provider_availability_notifications
    return unless available_changed?
    job = self.available ? ProviderBecameAvailableJob : ProviderBecameUnavailableJob
    Resque.enqueue(job, self.id)
  end

  def require_user
    contact_attrs = self.contact.attributes.with_indifferent_access rescue {}
    contact_attrs.delete(:id)
    self.user ||= User.where(email: contact_attrs[:email]).first if contact_attrs[:email]
    self.user ||= User.create(name: contact_attrs[:name],
                              email: contact_attrs[:email],
                              password: SecureRandom.uuid,
                              contact_attributes: contact_attrs) if contact_attrs && contact_attrs[:email] && contact_attrs[:name]
  end

  def setup_permissions
    self.user.add_role(:provider, self.company) if self.user && !standalone?
  end
end
