# To ensure proper loading order of feature pages and steps, take control of the load order

require 'support/features/page'
require 'support/features/angular_page'
require 'support/features/element'

%w(
  spec/support/features/page/**/*.rb
  spec/support/features/ui/**/*.rb
  spec/support/features/steps/**/*.rb
).each do |dir|
  Dir[Rails.root.join(dir)].sort.each { |f| require f }
end
