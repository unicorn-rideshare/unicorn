class WorkOrderMailer < ActionMailer::Base
  layout 'mailer'
  default from: "#{Settings.app.default_mailer_from_name} <#{Settings.app.default_mailer_from_address || Rails.application.config.default_mailer_from_address}>"
  default template_path: 'mailers/work_orders'

  class << self
    def deliver_customer_service_notification(work_order)
      customer_service_notification(work_order).deliver_now
    end

    def deliver_due_date_escalation(work_order)
      mail = []
      work_order.providers.each do |provider|
        mail << due_date_escalation(work_order, provider).deliver_now
      end
      mail
    end

    def deliver_morning_of_reminder(work_order)
      morning_of_reminder(work_order).deliver_now
    end

    def deliver_receipt(work_order)
      receipt(work_order).deliver_now
    end

    def deliver_reminder(work_order)
      reminder(work_order).deliver_now
    end

    def deliver_scheduled_confirmation(work_order)
      scheduled_confirmation(work_order).deliver_now
    end

    def deliver_upon_abandoned_follow_up(work_order)
      upon_abandoned_follow_up(work_order).deliver_now
    end

    def deliver_upon_completion_follow_up(work_order)
      upon_completion_follow_up(work_order).deliver_now
    end
  end

  def customer_service_notification(work_order)
    @work_order = work_order

    name = work_order.company.contact.name
    email = work_order.company.contact.email
    mail(to: "#{name} <#{email}>",
         subject: 'Attention Required')
  end

  def due_date_escalation(work_order, provider)
    @work_order = work_order
    @provider = provider

    name = provider.contact.name
    email = provider.contact.email
    mail(to: "#{name} <#{email}>",
         subject: 'Attention: Timeline at Risk')
  end

  def morning_of_reminder(work_order)
    @work_order = work_order

    url = "#{Settings.app.url}/work_orders/#{work_order.id.to_s}"
    @short_url = UrlShortenerService.shorten(url)

    name = work_order.customer.contact.name
    email = work_order.customer.contact.email
    mail(to: "#{name} <#{email}>",
         subject: 'Your Appointment Today')
  end

  def receipt(work_order)
    @work_order = work_order

    name = work_order.user.name
    email = work_order.user.email
    hour_of_day = work_order.started_at.to_time.hour
    time_of_day = (0..11).include?(hour_of_day) ? 'morning' : ((12..18).include?(hour_of_day) ? 'afternoon' : 'evening')  # FIXME/HACK...
    mail(to: "#{name} <#{email}>",
         subject: "Your #{work_order.started_at.strftime('%A')} #{time_of_day} trip with PRVD")
  end

  def reminder(work_order)
    @work_order = work_order

    url = "#{Settings.app.url}/work_orders/#{work_order.id.to_s}"
    @short_url = UrlShortenerService.shorten(url)

    name = work_order.customer.contact.name
    email = work_order.customer.contact.email
    mail(to: "#{name} <#{email}>",
         subject: 'Reminder About Your Upcoming Appointment')
  end

  def scheduled_confirmation(work_order)
    @work_order = work_order

    url = "#{Settings.app.url}/work_orders/#{work_order.id.to_s}"
    @short_url = UrlShortenerService.shorten(url)

    name = work_order.customer.contact.name
    email = work_order.customer.contact.email
    mail(to: "#{name} <#{email}>",
         subject: 'Your Appointment Has Been Scheduled')
  end

  def upon_abandoned_follow_up(work_order)
    @work_order = work_order

    url = "#{Settings.app.url}/work_orders/#{work_order.id.to_s}"
    @short_url = UrlShortenerService.shorten(url)

    name = work_order.customer.contact.name
    email = work_order.customer.contact.email
    mail(to: "#{name} <#{email}>",
         subject: 'We Missed You')
  end

  def upon_completion_follow_up(work_order)
    @work_order = work_order

    url = "#{Settings.app.url}/work_orders/#{work_order.id.to_s}"
    @short_url = UrlShortenerService.shorten(url)

    name = work_order.customer.contact.name
    email = work_order.customer.contact.email
    mail(to: "#{name} <#{email}>",
         subject: 'Thank You For Your Business')
  end
end
