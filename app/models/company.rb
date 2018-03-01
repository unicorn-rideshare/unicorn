class Company < ActiveRecord::Base
  include Authenticable
  include CompanySettings
  include Contactable
  include WorkOrderSettings

  resourcify

  validates :name, presence: true

  belongs_to :user
  validates :user, presence: true
  validates :user_id, readonly: true, on: :update

  has_many :categories

  has_many :customers

  has_many :dispatchers, after_add: :dispatcher_added, after_remove: :dispatcher_removed

  has_many :jobs

  has_many :markets

  has_many :products

  has_many :providers, after_add: :provider_added, after_remove: :provider_removed

  has_many :residential_floorplans

  has_many :routes

  has_many :tasks

  has_many :work_orders

  after_create :create_stripe_customer,
               :schedule_recurring_credit_card_charge_job,
               :update_permissions

  after_destroy :destroy_stripe_customer

  after_destroy :unschedule_recurring_credit_card_charge_job

  default_scope { order('id') }

  scope :greedy, ->() {
    includes(:contact, :tokens)
  }

  def account_balance
    0.00
  end

  def admins
    [user]
  end

  def communications_config
    cfg = (config[:customer_communications] || default_customer_communications_config).with_indifferent_access
    (cfg ? cfg.delete_if { |key, value| value.nil? } : {}).with_indifferent_access
  end

  def apply_stripe_coupon_code(stripe_coupon_code)
    return unless stripe_coupon_code
    Resque.enqueue(ApplyStripeCouponCodeJob, Company.name, self.id, stripe_coupon_code)
  end

  def create_stripe_credit_card(stripe_card_token)
    return unless stripe_card_token
    Resque.enqueue(CreateStripeCreditCardJob, Company.name, self.id, stripe_card_token)
  end

  def destroy_stripe_credit_card(stripe_card_id)
    return unless stripe_card_id
    Resque.enqueue(DestroyStripeCreditCardJob, Company.name, self.id, stripe_card_id)
  end

  def cancel_stripe_subscription(stripe_subscription_id)
    return unless stripe_subscription_id
    Resque.enqueue(CancelStripeSubscriptionJob, Company.name, self.id, stripe_subscription_id)
  end

  def create_stripe_subscription(stripe_plan_id, stripe_card_token = nil)
    return unless stripe_plan_id
    Resque.enqueue(CreateStripeSubscriptionJob, Company.name, self.id, stripe_plan_id, stripe_card_token)
  end

  def dot_hours_of_service_config
    cfg = (config[:dot_hours_of_service] || default_dot_hours_of_service_config).with_indifferent_access
    (cfg ? cfg.delete_if { |key, value| value.nil? } : {}).with_indifferent_access
  end

  def has_card?
    return false unless stripe_customer
    stripe_customer.default_source.present?
  end

  def require_contact_time_zone?
    true
  end

  def stripe_customer
    return nil unless self.stripe_customer_id
    @stripe_customer ||= begin
      Stripe::Customer.retrieve(self.stripe_customer_id) rescue nil
    end
  end

  def work_order_components
    config[:components]
  end

  private

  def create_stripe_customer
    return if self.stripe_customer_id
    Resque.enqueue(CreateStripeCustomerJob, Company.name, self.id)
  end

  def destroy_stripe_customer
    return unless self.stripe_customer_id
    Resque.enqueue(DestroyStripeCustomerJob, self.stripe_customer_id)
  end

  def dispatcher_added(dispatcher)
    dispatcher.user.add_role(:dispatcher, self) if dispatcher.user && dispatcher.errors.size == 0
  end

  def dispatcher_removed(dispatcher)
    dispatcher.user.remove_role(:dispatcher, self) if dispatcher.user && dispatcher.errors.size == 0
  end

  def provider_added(provider)
    provider.user.add_role(:provider, self) if provider.user && provider.errors.size == 0
  end

  def provider_removed(provider)
    provider.user.remove_role(:provider, self) if provider.user && provider.errors.size == 0
  end

  def recurring_credit_card_charge_schedule_name
    "#{RecurringCreditCardChargeJob.name}_#{Company.name}_#{self.id}"
  end

  def schedule_recurring_credit_card_charge_job
    Resque.set_schedule(recurring_credit_card_charge_schedule_name, { class: RecurringCreditCardChargeJob.name,
                                                                      args: self.id,
                                                                      every: ['30d', { first_in: 30.days }],
                                                                      persist: true })
  end

  def unschedule_recurring_credit_card_charge_job
    Resque.remove_schedule(recurring_credit_card_charge_schedule_name)
  end

  def update_permissions
    user.add_role(:admin, self)
  end
end
