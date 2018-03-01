RSpec.configure do |config|
  config.before(:each) do
    allow(Timezone::Zone).to receive(:new)
    allow(Timezone::Zone).to receive(:new).with(latlon: anything) { Timezone::Zone.new(zone: TimeZone.all.map(&:tzinfo).map(&:to_s).sample) }
  end
end
