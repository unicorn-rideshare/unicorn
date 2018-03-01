object @provider_origin_assignment => nil

attributes :id,
           :status

node(:provider) do |provider_origin_assignment|
  partial 'providers/show', object: provider_origin_assignment.provider
end

node(:origin) do |provider_origin_assignment|
  partial 'origins/show', object: provider_origin_assignment.origin
end

node(:start_date) do |provider_origin_assignment|
  provider_origin_assignment.start_date? ? provider_origin_assignment.start_date.iso8601 : nil
end

node(:end_date) do |provider_origin_assignment|
  provider_origin_assignment.end_date? ? provider_origin_assignment.end_date.iso8601 : nil
end

node(:scheduled_start_at) do |provider_origin_assignment|
  provider_origin_assignment.scheduled_start_at? ? provider_origin_assignment.scheduled_start_at.iso8601 : nil
end

node(:started_at) do |provider_origin_assignment|
  provider_origin_assignment.started_at? ? provider_origin_assignment.started_at.iso8601 : nil
end

node(:ended_at) do |provider_origin_assignment|
  provider_origin_assignment.ended_at? ? provider_origin_assignment.ended_at.iso8601 : nil
end
