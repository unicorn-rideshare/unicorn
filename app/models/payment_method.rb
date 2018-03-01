class PaymentMethod < ActiveRecord::Base

  belongs_to :user
  validates :user, presence: true
  validates :user_id, readonly: true, on: :update

  validates :type, inclusion: { in: %w(card) }

  validates_presence_of :stripe_token
  validates_presence_of :stripe_credit_card_id

  validate :validate_user_is_stripe_customer

  after_create :create_stripe_credit_card

  after_destroy :destroy_stripe_credit_card

  class << self
    def inheritance_column
      'subclass'
    end
  end

  def charge(amount, description)
    Stripe::Charge.create(
      amount: amount,
      currency: 'usd',
      customer: self.user.stripe_customer_id,
      source: self.stripe_credit_card_id,
      description: description,
    )
  end

  private

  def create_stripe_credit_card
    return unless self.stripe_token
    begin
      CreateStripeCreditCardJob.perform(User.name, self.user_id, self.stripe_token)
    rescue Stripe::CardError => e
      errors.add(e.code, e.message)
    end
  end

  def destroy_stripe_credit_card
    return unless self.stripe_credit_card_id
    begin
      Resque.enqueue(DestroyStripeCreditCardJob, User.name, self.user_id, self.stripe_credit_card_id)
    rescue Stripe::CardError => e
      errors.add(e.code, e.message)
    end
  end

  def validate_user_is_stripe_customer
    errors.add(:user, I18n.t('errors.message.user_must_be_stripe_customer')) unless self.user.stripe_customer_id.present?
  end
end
