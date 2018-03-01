class DestroyStripeCreditCardJob
  @queue = :high

  class << self
    def perform(clazz, id, stripe_credit_card_id)
      instance = clazz.constantize.unscoped.find(id) rescue nil
      return unless instance && stripe_credit_card_id

      stripe_customer = instance.try(:stripe_customer)
      return unless stripe_customer

      stripe_customer.sources.retrieve(stripe_credit_card_id).try(:delete)
    end
  end
end
