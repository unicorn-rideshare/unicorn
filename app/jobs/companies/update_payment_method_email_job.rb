class UpdatePaymentMethodEmailJob
  @queue = :high

  class << self
    def perform(company_id)
      company = Company.unscoped.find(company_id)
      return if company.has_card?

      # no-op for now
    end
  end
end
