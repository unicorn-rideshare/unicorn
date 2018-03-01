object @origin => nil

attributes :id,
           :warehouse_number

node(:contact) do |origin|
  partial 'contacts/show', object: origin.contact
end

node(:effective_dispatcher_origin_assignments_count) do |origin|
  origin.dispatcher_origin_assignments.in_effect(Date.today).size
end

node(:effective_provider_origin_assignments_count) do |origin|
  origin.provider_origin_assignments.in_effect(Date.today).size
end
