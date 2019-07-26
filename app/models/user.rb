class User < ActiveRecord::Base
  include Attachable
  include Authenticable
  include Contactable
  include Invitable
  include Locatable

  has_secure_password validations: false

  resourcify
  rolify

  validates :password, length: { minimum: 6 }, allow_nil: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  has_many :companies

  validates :name, presence: true
  has_many :customers

  has_many :devices

  has_many :dispatchers

  has_many :jwt_tokens

  has_many :payment_methods

  has_many :providers

  has_many :work_orders

  has_many :wallets

  has_many :messages_sent,
           class_name: Message.name,
           foreign_key: :sender_id

  has_many :messages_received,
           class_name: Message.name,
           foreign_key: :recipient_id

  validate :valid_preferences

  after_create :create_prvd_user

  after_create :create_stripe_customer

  after_destroy :destroy_stripe_customer

  scope :active, ->(checkin_recency_in_minutes = 10) {  # TODO: add test coverage
    where('users.last_checkin_at IS NOT NULL AND users.last_checkin_at >= ?::timestamp - INTERVAL \'? minutes\'',
          DateTime.now.utc.to_s, checkin_recency_in_minutes)
  }

  scope :nearby, ->(coordinate, radius_in_miles = 5) {  # TODO: add test coverage
    where('ST_DistanceSphere(users.last_checkin_geom, ST_MakePoint(?, ?)) <= ?',
          coordinate.longitude, coordinate.latitude, radius_in_miles * 1609.34)
  }

  class << self
    def authenticate(email, password)
      User.find_by(email: email).try(:authenticate, password) if password
    end

    def authenticate_fb_access_token(access_token)
      user = User.find_by_fb_access_token(access_token)
      return false unless user
      user
    end

    def find_by_fb_access_token(access_token)
      fb_token = FacebookService.debug_token(access_token)
      return nil unless fb_token && fb_token[:user_id] && fb_token[:is_valid]
      user = User.find_by(fb_user_id: fb_token[:user_id])
      user.update_attributes(fb_access_token: access_token,
                             fb_access_token_expires_at: fb_token[:expires_at])
      user
    end

    def invite_key_fields
      [:name, :email]
    end
  end

  def apply_stripe_coupon_code(stripe_coupon_code)
    return unless stripe_coupon_code
    Resque.enqueue(ApplyStripeCouponCodeJob, User.name, self.id, stripe_coupon_code)
  end

  def cancel_stripe_subscription(stripe_subscription_id)
    return unless stripe_subscription_id
    Resque.enqueue(CancelStripeSubscriptionJob, User.name, self.id, stripe_subscription_id)
  end

  def create_stripe_subscription(stripe_plan_id, stripe_card_token = nil)
    return unless stripe_plan_id
    Resque.enqueue(CreateStripeSubscriptionJob, User.name, self.id, stripe_plan_id, stripe_card_token)
  end

  def default_company_id
    return preferences[:default_company_id].to_i if preferences[:default_company_id]
    return company_ids.first if company_ids.size > 0
    return dispatchers.first.company_id if dispatcher_ids.size > 0
    providers.first.company_id if provider_ids.size > 0
  end

  def default_ethereum_wallet
    wallets.where(type: 'eth').first
  end

  def is_company_admin?
    company_ids.size > 0
  end

  def is_dispatcher?
    dispatcher_ids.size > 0
  end

  def is_provider?
    provider_ids.size > 0
  end

  def is_supervisor?
    is_provider? && roles.map(&:name).uniq.map(&:to_sym).include?(:supervisor)
  end

  def preferences
    super.with_indifferent_access
  end

  def require_contact_time_zone?
    true
  end

  def reset_password
    self.reset_password_token = SecureRandom.uuid
    self.reset_password_sent_at = DateTime.now
    Resque.enqueue(SendResetPasswordNotificationJob, self.id) if save!
  end

  def stripe_customer
    return nil unless self.stripe_customer_id
    @stripe_customer ||= begin
      Stripe::Customer.retrieve(self.stripe_customer_id) rescue nil
    end
  end

  def create_prvd_api_token(password)
    jwt_token = ENV['PROVIDE_APPLICATION_API_TOKEN']
    return unless jwt_token
    IdentService.authenticate(jwt_token, {
      email: self.email,
      password: password,
    })
  end

  def create_prvd_wallet(network_id = nil)
    network_id ||= ENV['PROVIDE_NETWORK_ID']
    jwt_token = jwt_tokens.first.token rescue nil
    status, _, resp = BlockchainService.create_wallet(jwt_token, { network_id: network_id }) if jwt_token
    wallets.create(type: 'eth',
                   address: resp['address'],
                   wallet_id: resp['id']) if status == 201 && resp
  end

  def update(attrs)
    success = super(attrs)
    IdentService.update_user(self.jwt_tokens.last.token, self.prvd_user_id, attrs) if success && self.prvd_user_id && self.jwt_tokens.size > 0
    success
  end

  private

  def create_prvd_user
    api_token = ENV['PROVIDE_APPLICATION_API_TOKEN']
    return unless api_token
    status, _, prvd_user = IdentService.create_user(api_token, {
      name: self.name,
      email: self.email,
      password: self.password,
    })
    if status == 201 && prvd_user && prvd_user['id']
      self.update_attributes(prvd_user_id: prvd_user['id']) if prvd_user && prvd_user['id']
      status, resp = self.create_prvd_api_token(self.password)
      jwt_token = resp['token'] if status == 201 && resp && resp['token']
      self.jwt_tokens.create(token: jwt_token['token']) if status == 201 && jwt_token && jwt_token['token']
      self.create_prvd_wallet
    end
  end

  def create_stripe_customer
    return if self.stripe_customer_id
    Resque.enqueue(CreateStripeCustomerJob, User.name, self.id)
  end

  def destroy_stripe_customer
    return unless self.stripe_customer_id
    Resque.enqueue(DestroyStripeCustomerJob, self.stripe_customer_id)
  end

  def invitation_received(invitation)
    Resque.enqueue(SendInvitationJob, invitation.id)
  end

  def valid_preferences
    company_id = preferences[:default_company_id].try(:to_i)
    if company_id
      accessible_company_ids = ((company_ids || []) + dispatchers.map(&:company_id) + providers.map(&:company_id)).uniq
      errors.add(:preferences, I18n.t('errors.messages.user_default_company_id_must_be_accessible')) unless accessible_company_ids.include?(company_id)
    end
  end
end
