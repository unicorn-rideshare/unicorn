class CreateStripeCreditCardJob
  @queue = :high

  class << self
    def perform(clazz, id, stripe_card_token)
      instance = clazz.constantize.unscoped.find(id) rescue nil
      return unless instance && stripe_card_token

      stripe_customer = instance.try(:stripe_customer)
      return unless stripe_customer

      previous_stripe_credit_card_id = instance.try(:stripe_credit_card_id)

      card = stripe_customer.sources.create(source: stripe_card_token)
      instance.update_attribute(:stripe_credit_card_id, card.id) if instance.respond_to?(:stripe_credit_card_id) && card.try(:id)

      destroy_previous_card = previous_stripe_credit_card_id && card.try(:id)
      instance.destroy_stripe_credit_card(previous_stripe_credit_card_id) if destroy_previous_card
    end
  end
end
