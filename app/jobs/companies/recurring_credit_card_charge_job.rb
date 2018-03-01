class RecurringCreditCardChargeJob
  @queue = :high

  class << self
    def perform(company_id)
      company = Company.unscoped.find(company_id)
      balance = (company.account_balance * 100).to_i # convert to pennies
      return unless balance > 0

      stripe_customer = company.stripe_customer rescue nil
      return unless stripe_customer

      Resque.enqueue(UpdatePaymentMethodEmailJob, company_id) unless company.has_card?
      Stripe::Charge.create(amount: balance,
                            currency: 'usd',
                            customer: company.stripe_customer_id,
                            description: "Charging #{company.name} $#{balance / 100.0}") if company.has_card?
    end
  end
end
