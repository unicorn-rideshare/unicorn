class CancelStripeSubscriptionJob
  @queue = :high

  class << self
    def perform(clazz, id, stripe_subscription_id)
      instance = clazz.constantize.unscoped.find(id) rescue nil
      return unless instance && stripe_subscription_id

      stripe_customer = instance.try(:stripe_customer)
      return unless stripe_customer

      stripe_customer.subscriptions.retrieve(stripe_subscription_id).try(:delete)
    end
  end
end
