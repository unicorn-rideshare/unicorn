class PaymentService
  class << self
    def validate_and_tokenize_card(card_number, exp_month, exp_year, cvc, amount=50, description='Card validation')
      tokenization_params = {
        card: {
          number: card_number,
          exp_month: exp_month,
          exp_year: exp_year,
          cvc: cvc,
        }
      }
      charge = Stripe::Charge.create(
        amount: amount,
        currency: 'usd',
        description: description,
        source: Stripe::Token.create(tokenization_params),
      )
      Stripe::Refund.create(charge: charge)
      Stripe::Token.create(tokenization_params)
    end
  end
end
