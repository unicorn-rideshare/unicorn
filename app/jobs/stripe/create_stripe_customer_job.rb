class CreateStripeCustomerJob
  @queue = :high

  class << self
    def perform(clazz, id)
      instance = clazz.constantize.unscoped.find(id) rescue nil
      return if instance.try(:stripe_customer_id)

      stripe_customer_id = Stripe::Customer.create(email: instance.try(:email) || instance.try(:user).try(:email),
                                                   description: instance.try(:name)).id
      instance.update_attribute(:stripe_customer_id, stripe_customer_id)
    end
  end
end
