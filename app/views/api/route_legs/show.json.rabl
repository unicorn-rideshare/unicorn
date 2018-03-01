object @route_leg => nil

attributes :id,
           :actual_traffic,
           :estimated_traffic

node(:estimated_start_at) do |route_leg|
  route_leg.estimated_start_at ? route_leg.estimated_start_at.iso8601 : nil
end

node(:actual_start_at) do |route_leg|
  route_leg.actual_start_at ? route_leg.actual_start_at.iso8601 : nil
end

node(:estimated_end_at) do |route_leg|
  route_leg.estimated_end_at ? route_leg.estimated_end_at.iso8601 : nil
end

node(:actual_end_at) do |route_leg|
  route_leg.actual_end_at ? route_leg.actual_end_at.iso8601 : nil
end

node(:estimated_end_at_on_start) do |route_leg|
  route_leg.estimated_end_at_on_start ? route_leg.estimated_end_at_on_start.iso8601 : nil
end

node(:work_order_id) do |route_leg|
  route_leg.work_order ? route_leg.work_order.id : nil
end
