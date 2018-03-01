object @route => nil

attributes :id,
           :dispatcher_origin_assignment_id,
           :provider_origin_assignment_id,
           :name,
           :identifier,
           :status,
           :fastest_here_api_route_id,
           :shortest_here_api_route_id

node(:date) do |route|
  route.date.iso8601
end

node(:scheduled_start_at) do |route|
  route.scheduled_start_at ? route.scheduled_start_at.iso8601 : nil
end

node(:scheduled_end_at) do |route|
  route.scheduled_end_at ? route.scheduled_end_at.iso8601 : nil
end

node(:started_at) do |route|
  route.started_at ? route.started_at.iso8601 : nil
end

node(:ended_at) do |route|
  route.ended_at ? route.ended_at.iso8601 : nil
end

node(:loading_started_at) do |route|
  route.loading_started_at ? route.loading_started_at.iso8601 : nil
end

node(:loading_ended_at) do |route|
  route.loading_ended_at ? route.loading_ended_at.iso8601 : nil
end

node(:unloading_started_at) do |route|
  route.unloading_started_at ? route.unloading_started_at.iso8601 : nil
end

node(:unloading_ended_at) do |route|
  route.unloading_ended_at ? route.unloading_ended_at.iso8601 : nil
end

node(:incomplete_manifest) do |route|
  route.incomplete_manifest?
end

node(:items_loaded) do |route|
  partial 'products/index', object: route.items_loaded
end

node(:dispatcher_origin_assignment) do |route|
  partial 'dispatcher_origin_assignments/show', object: route.dispatcher_origin_assignment
end if locals[:include_dispatcher_origin_assignment] || @include_dispatcher_origin_assignment

node(:provider_origin_assignment) do |route|
  partial 'provider_origin_assignments/show', object: route.provider_origin_assignment
end if locals[:include_provider_origin_assignment] || @include_provider_origin_assignment

node(:legs) do |route|
  partial 'route_legs/index', object: route.legs
end if locals[:include_legs] || @include_legs

node(:work_orders) do |route|
  partial 'work_orders/index', object: route.work_orders.greedy
end if locals[:include_work_orders] || @include_work_orders
