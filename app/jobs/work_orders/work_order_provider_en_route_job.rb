class WorkOrderProviderEnRouteJob
  @queue = :high

  class << self
    def perform(work_order_id, provider_id = nil)
      work_order = WorkOrder.unscoped.find(work_order_id) rescue nil
      return unless work_order

      company = work_order.company

      providers = work_order.work_order_providers.map(&:provider)
      provider = providers.select { |provider| provider.id == provider_id.to_i }.first if provider_id
      provider = providers.first if provider.nil? && providers.size == 1

      customer = work_order.customer
      customer_mobile = customer.try(:contact).try(:mobile)

      if provider && customer && customer_mobile && work_order.customer_communications_enabled?
        provider_coordinate = provider.last_checkin ? provider.last_checkin.coordinate : nil
        eta = provider_coordinate ? RoutingService.driving_eta([provider_coordinate, work_order.customer.contact.coordinate]) : nil
        short_url = UrlShortenerService.shorten("#{Settings.app.url}/work_orders/#{work_order.id.to_s}")

        body = "Hi #{customer.contact.first_name}! #{provider.contact.first_name} with #{company.name} is on the way to you now"
        body += " and should arrive in #{round(eta)} minutes" if eta
        body += "! Track #{provider.contact.first_name.possessive} location here: #{short_url}"

        TwilioService.send_sms([customer_mobile], body)
      end
    end

    def round(eta)
      rounded_eta = eta.round(-1)
      rounded_eta += 10 if rounded_eta < eta
      rounded_eta += 5 if rounded_eta - eta < 5
      rounded_eta
    end
  end
end
