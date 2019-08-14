class DestroyStripeAccountJob
  @queue = :high

  class << self
    def perform(stripe_account_id)
      stripe_account = Stripe::Account.retrieve(stripe_account_id) rescue nil
      stripe_account.try(:delete)
    end
  end
end
