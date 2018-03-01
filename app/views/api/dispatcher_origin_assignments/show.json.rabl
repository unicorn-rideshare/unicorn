object @dispatcher_origin_assignment => nil

attributes :id

node(:dispatcher) do |dispatcher_origin_assignment|
  partial 'dispatchers/show', object: dispatcher_origin_assignment.dispatcher
end

node(:origin) do |dispatcher_origin_assignment|
  partial 'origins/show', object: dispatcher_origin_assignment.origin
end

node(:start_date) do |dispatcher_origin_assignment|
  dispatcher_origin_assignment.start_date? ? dispatcher_origin_assignment.start_date.iso8601 : nil
end

node(:end_date) do |dispatcher_origin_assignment|
  dispatcher_origin_assignment.end_date? ? dispatcher_origin_assignment.end_date.iso8601 : nil
end
