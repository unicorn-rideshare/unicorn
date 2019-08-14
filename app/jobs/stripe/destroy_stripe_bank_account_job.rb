class DestroyStripeBankAccountJob
  @queue = :high

  class << self
    def perform(clazz, id, stripe_bank_account_id)
      instance = clazz.constantize.unscoped.find(id) rescue nil
      return unless instance && stripe_bank_account_id

      stripe_account = instance.try(:stripe_account)
      return unless stripe_account

      Stripe::Account.delete_external_account(instance.stripe_account_id, stripe_bank_account_id)
    end
  end
end
