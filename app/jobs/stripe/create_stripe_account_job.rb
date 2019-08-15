class CreateStripeAccountJob
  @queue = :high

  class << self
    def perform(clazz, id)
      instance = clazz.constantize.unscoped.find(id) rescue nil
      return if instance.try(:stripe_account_id)

      stripe_account = Stripe::Account.create({
        country: 'US', # FIXME-- read country from contactable...
        type: 'custom',
        requested_capabilities: ['transfers', 'card_payments'],
      })

      stripe_account_id = stripe_account.try(:id)
      raise RuntimeError('Account creation failed') if stripe_account_id.nil?

      instance.update_attribute(:stripe_account_id, stripe_account_id)
    end
  end
end
