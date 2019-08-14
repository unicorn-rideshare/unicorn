class CreateStripeBankAccountJob
  @queue = :high

  class << self
    def perform(clazz, id, stripe_bank_account_token)
      instance = clazz.constantize.unscoped.find(id) rescue nil
      return unless instance && stripe_card_token

      stripe_account = instance.try(:stripe_account)
      return unless stripe_account

      previous_stripe_bank_account_id = instance.try(:stripe_bank_account_id)

      bank_account = Stripe::Account.create_external_account(
      	instance.stripe_account_id,
      	{ external_account: stripe_bank_account_token }
      )

      instance.update_attribute(:stripe_bank_account_id, bank_account.id) if instance.respond_to?(:stripe_bank_account_id) && bank_account.try(:id)
      destroy_previous_bank_account = previous_stripe_bank_account_id && bank_account.try(:id)
      instance.destroy_stripe_bank_account(previous_stripe_bank_account_id) if destroy_previous_bank_account
    end
  end
end
