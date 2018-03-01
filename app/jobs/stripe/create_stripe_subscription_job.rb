class CreateStripeSubscriptionJob
  @queue = :high

  class << self
    def perform(clazz, id, stripe_plan_id, stripe_card_token = nil)
      instance = clazz.constantize.unscoped.find(id) rescue nil
      return unless instance && stripe_plan_id

      stripe_customer = instance.try(:stripe_customer)
      return unless stripe_customer

      CreateStripeCreditCardJob.perform(clazz, id, stripe_card_token) if stripe_card_token

      stripe_customer.subscriptions.create(plan: stripe_plan_id)
    end
  end
end
