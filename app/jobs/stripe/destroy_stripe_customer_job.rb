class DestroyStripeCustomerJob
  @queue = :high

  class << self
    def perform(stripe_customer_id)
      stripe_customer = Stripe::Customer.retrieve(stripe_customer_id) rescue nil
      stripe_customer.try(:delete)
    end
  end
end
