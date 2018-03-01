object @work_order_provider => nil

attributes :id,
           :hourly_rate,
           :hourly_rate_due,
           :flat_fee,
           :flat_fee_due,
           :estimated_duration,
           :estimated_cost,
           :estimated_revenue,
           :duration,
           :rating

node(:provider) do |work_order_provider|
  partial 'providers/show', object: work_order_provider.provider
end

node(:confirmed_at) do |work_order_provider|
  work_order_provider.confirmed_at ? work_order_provider.confirmed_at.iso8601 : nil
end

node(:started_at) do |work_order_provider|
  work_order_provider.started_at ? work_order_provider.started_at.iso8601 : nil
end

node(:ended_at) do |work_order_provider|
  work_order_provider.ended_at ? work_order_provider.ended_at.iso8601 : nil
end

node(:arrived_at) do |work_order_provider|
  work_order_provider.arrived_at ? work_order_provider.arrived_at.iso8601 : nil
end

node(:abandoned_at) do |work_order_provider|
  work_order_provider.abandoned_at ? work_order_provider.abandoned_at.iso8601 : nil
end

node(:canceled_at) do |work_order_provider|
  work_order_provider.canceled_at ? work_order_provider.canceled_at.iso8601 : nil
end

node(:timed_out_at) do |work_order_provider|
  work_order_provider.timed_out_at ? work_order_provider.timed_out_at.iso8601 : nil
end

node(:checkin_coordinates) do |work_order_provider|
  work_order_provider.work_order.checkin_coordinates(work_order_provider.provider)
end if (locals[:include_checkin_coordinates] || @include_checkin_coordinates)
