object @time_zone => nil

node(:id) { |time_zone| time_zone.name }
node(:name) { |time_zone| t(time_zone.name, scope: %w(time_zones)) }
