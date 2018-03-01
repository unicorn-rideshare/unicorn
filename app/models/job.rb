class Job < ActiveRecord::Base
  include Attachable
  include Commentable
  include Expensable
  include Notifiable
  include StateMachine

  resourcify

  belongs_to :company
  validates :company, presence: true
  validates :company_id, readonly: true, on: :update

  belongs_to :customer
  validates :customer, presence: true
  validates :customer_id, readonly: true, on: :update
  validate :customers_company_must_match

  validate :validate_type

  has_many :job_products
  accepts_nested_attributes_for :job_products

  has_many :tasks

  has_and_belongs_to_many :work_orders,
                          after_add: :work_order_added,
                          after_remove: :work_order_removed

  after_create :initialize_started_at

  after_save :read_job_product_ids

  before_save :calculate_contract_revenue, if: lambda { self.quoted_price_per_sq_ft && self.total_sq_ft && (self.new_record? || self.total_sq_ft_changed? || self.quoted_price_per_sq_ft_changed?) }

  default_scope { order('jobs.updated_at DESC') }

  scope :greedy, ->() {
    includes(:attachments, :customer)
  }

  aasm column: :status, whiny_transitions: false do
    # state :bidding, initial: true
    # state :lost
    # state :awarded
    state :configuring, initial: true
    state :in_progress
    state :pending_completion
    state :completed
    state :canceled

    event :start do
      transitions from: [:configuring], to: :in_progress
    end

    event :cancel do
      transitions from: [:configuring, :in_progress], to: :canceled

      before do
        self.work_orders.each do |work_order|
          work_order.cancel! unless work_order.disposed? rescue nil
        end

        self.canceled_at = DateTime.now
      end
    end

    event :close do
      transitions from: [:in_progress], to: :pending_completion

      before do
        self.job_duration = DateTime.now.to_i - self.started_at.to_i
      end
    end

    event :complete do
      transitions from: [:in_progress, :pending_completion], to: :completed

      before do
        self.ended_at = DateTime.now
        self.duration = self.ended_at.to_i - self.started_at.to_i
        self.job_duration = self.duration unless self.job_duration
      end
    end
  end

  class << self
    def inheritance_column
      'subclass'
    end
  end

  def contract_revenue
    revenue = super
    return revenue if revenue
    expensed_amount + labor_revenue + materials_revenue
  end

  def cost
    expensed_amount + labor_cost + materials_cost
  end

  def expensed_amount
    job_expenses = expenses.map(&:amount).reject { |amount| amount.nil? }.reduce(&:+).to_f
    job_expenses + work_orders.map(&:expensed_amount).reduce(&:+).to_f
  end

  def labor_cost
    work_orders.map(&:labor_cost).reduce(&:+).to_f
  end

  def labor_cost_per_sq_ft
    return nil unless labor_cost && total_sq_ft && total_sq_ft != 0.0
    (labor_cost / total_sq_ft).round(2)
  end

  def labor_cost_percentage_of_revenue
    return nil unless labor_cost && contract_revenue && contract_revenue != 0.0
    (labor_cost / contract_revenue).round(2)
  end

  def labor_revenue
    work_orders.map(&:labor_revenue).reduce(&:+).to_f
  end

  def materials
    job_products
  end

  def materials_cost
    materials.map(&:estimated_cost).reject { |estimated_cost| estimated_cost.nil? }.reduce(&:+).to_f
  end

  def materials_cost_per_sq_ft
    return nil unless materials_cost && total_sq_ft && total_sq_ft != 0.0
    (materials_cost / total_sq_ft).round(2)
  end

  def materials_cost_percentage_of_revenue
    return nil unless materials_cost && contract_revenue && contract_revenue != 0.0
    (materials_cost / contract_revenue).round(2)
  end

  def materials_revenue
    materials.map(&:revenue).reject { |revenue| revenue.nil? }.reduce(&:+).to_f
  end

  def profit
    return nil unless contract_revenue && cost
    contract_revenue - cost
  end

  def profit_margin
    return nil unless profit && contract_revenue && contract_revenue != 0.0
    (profit / contract_revenue).round(2)
  end

  def profit_per_sq_ft
    return nil unless profit && total_sq_ft && total_sq_ft != 0.0
    (profit / total_sq_ft).round(2)
  end

  def is_provider?(provider)
    work_orders.map(&:providers).flatten.uniq.include?(provider)
  end

  def is_supervisor?(provider)
    supervisors.include?(provider)
  end

  def provider_work_orders(provider)
    work_orders.select { |work_order| work_order.providers.include?(provider) }
  end

  def providers
    cached_supervisors = self.supervisors
    User.with_role(:provider, self).map(&:providers).flatten.select { |provider| provider.company_id == self.company_id }.reject { |provider| cached_supervisors.include?(provider) }
  end

  def supervisors
    User.with_role(:supervisor, self).map(&:providers).flatten.select { |provider| provider.company_id == self.company_id }
  end

  def supervisors=(supervisors)
    removed_supervisors = self.supervisors.reject { |supervisor| supervisors.include?(supervisor) }
    removed_supervisors.each { |removed_supervisor| removed_supervisor.user.remove_role(:supervisor, self) if removed_supervisor.user }
    supervisors.each { |supervisor| supervisor.user.add_role(:supervisor, self) if supervisor.user }
  end

  def total_sq_ft
    total_sq_ft = super
    return total_sq_ft if total_sq_ft && total_sq_ft > 0.0
    materials.map(&:total_sq_ft).reduce(&:+).to_f
  end

  def job_products_attributes=(job_products_attributes)
    product_ids = job_products_attributes.map { |attrs| (attrs[:product_id] || materials.find(attrs[:id]).product_id).to_i }
    read_job_product_ids unless @job_product_ids_was
    product_ids_was = @job_product_ids_was || []
    removed_job_product_ids = []

    product_ids_was.each do |product_id|
      job_product_id = job_products.select { |job_product| job_product.product_id == product_id }.first.id
      removed_job_product_ids << job_product_id unless product_ids.include?(product_id)
    end

    super(job_products_attributes)

    removed_job_product_ids.each do |removed_job_product_id|
      job_product = job_products.find(removed_job_product_id)
      job_product.destroy
    end
  end

  def send_attachment_notification?(notification_type, attachment)
    !(attachment.tags || []).map(&:to_sym).include?(:tile)
  end

  private

  def attachment_added(attachment)
    # no-op
  end

  def calculate_contract_revenue
    return unless total_sq_ft && quoted_price_per_sq_ft
    self.contract_revenue = total_sq_ft * quoted_price_per_sq_ft
  end

  def customers_company_must_match
    return unless company_id && customer_id
    match = customer.company_id == company_id
    errors.add(:customer_id, :customer_company_must_match_job_company) unless match
  end

  def initialize_started_at
    update_attribute(:started_at, self.created_at)
  end

  def notification_params(notification_type)
    {}
  end

  def notification_recipients(notification_type)
    recipients = []
    self.company.admins.map { |user| recipients << user }
    self.supervisors.map { |supervisor| recipients << supervisor.user if supervisor.user.present? }
    self.providers.map { |provider| recipients << provider.user if provider.user.present? }
    recipients
  end

  def read_job_product_ids
    @job_product_ids_was = job_products.map(&:product_id)
  end

  def validate_type
    errors.add(:type, :job_type_invalid) unless [:commercial, :residential, :punchlist].include?(self.type.to_s.downcase.to_sym)
  end

  def work_order_added(work_order)
    work_order.update_attribute(:job_id, id)
    work_order.providers.each do |provider|
      user = provider.user
      user.add_role(:provider, self) if user && !user.has_role?(:provider, self)
    end
  end

  def work_order_removed(work_order)
    work_order.update_attribute(:job_id, nil)
    work_order.providers.each do |provider|
      user = provider.user
      user.remove_role(:provider, self) if user && user.has_role?(:provider, self) && !is_supervisor?(provider) && provider_work_orders(provider).size == 0
    end
  end
end
