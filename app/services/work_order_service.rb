class WorkOrderService

  class << self

    def calculate_availability(options) # rubocop:disable CyclomaticComplexity, MethodLength
      return nil if options[:start_date].nil? || options[:end_date].nil?

      provider_ids = options[:provider_ids] || []

      start_at = Time.parse(options[:start_date])
      end_at = Time.parse(options[:end_date])
      range = start_at..end_at

      steps = ((end_at - start_at) / 30.minutes).to_i
      availability = steps.times.map { |step| start_at + step * 30.minutes }

      now = Time.now
      availability.select! { |time| time >= now }

      Provider.where(id: provider_ids).to_a.each do |provider|
        provider.work_orders.scheduled.in_date_range(range).each do |work_order|
          availability.reject! do |time|
            my_start_at = time
            my_end_at = time + (work_order.estimated_duration || 0).minutes
            (work_order.scheduled_start_at <= my_start_at && my_start_at < work_order.scheduled_end_at) ||
                (work_order.scheduled_start_at < my_end_at && my_end_at <= work_order.scheduled_end_at) ||
                (my_start_at <= work_order.scheduled_start_at && work_order.scheduled_start_at < my_end_at) ||
                (my_start_at < work_order.scheduled_end_at && work_order.scheduled_end_at <= my_end_at)
          end
        end
      end

      time_zone = options[:time_zone]

      if time_zone.nil? && options[:customer_id]
        customer = Customer.find(options[:customer_id])
        time_zone = customer.contact.time_zone_id
      end

      time_zone = 'UTC' unless time_zone

      availability.map { |time|
        time.in_time_zone(time_zone).iso8601
      }
    end
  end
end
