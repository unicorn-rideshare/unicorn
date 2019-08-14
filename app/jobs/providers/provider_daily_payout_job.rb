class ProviderDailyPayoutJob
  include Unicorn::Notifications

  @queue = :high

  class << self
    def perform(provider_id, date)
      provider = Provider.unscoped.find(provider_id) rescue nil
      return unless provider

      new(provider, date).process
    end
  end

  def initialize(provider, date)
    @provider = provider
    @date = Date.parse(date)
    @amount = 0.0
  end

  def process
    resolve_eligible_work_orders
    calculate_payment
    send_payment
    send_push_notifications
  end

  def resolve_eligible_work_orders
    @eligible_work_orders = provider.work_orders.completed.unpaid.started_on(@date)
  end

  def calculate_payment
    @amount = @eligible_work_orders.map(&:calculate_revenue).reduce(&:+)
  end

  def currency
    'usd'
  end

  def send_payment
    return unless @amount > 0.0
    # TODO: verifiy regional parity to ensure support prior to attempting transaction...
    payout = Stripe::Payout.create({
      amount: @amount*100,
      currency: currency,
    }, { stripe_account: @provider.stripe_account_id })

    remittance_id = payout.try(:id)
    raise RuntimeError('Remittance failed') if remittance_id.nil?

    @eligible_work_orders.each do |work_order|
      work_order.update_attributes(remittance_id: remittance_id, 
                                   payment_remitted: true)
    end
  end

  def mobile_notification_params
    {
        type: 'provider_payout_processed',
        provider_id: @provider.id,
    }
  end

  def payment_payload
    {
      date: @payout.date.iso8601,
      amount: @amount,
      currency: currency,
    }
  end

  def user
    @provider.user
  end

  def users
    [user]
  end

  def websocket_notification_params
    payload = Rabl::Renderer.new('providers/show',
                                 @provider,
                                 view_path: 'app/views',
                                 format: 'hash').render rescue nil

    { message: 'provider_payout_processed', payload: payment_payload }
  end
end
