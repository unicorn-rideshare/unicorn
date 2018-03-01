RSpec.configure do |config|
  config.before(:each) do
    allow_any_instance_of(User).to receive(:create_prvd_user) { }
    allow_any_instance_of(User).to receive(:create_stripe_customer) { }

    allow_any_instance_of(Company).to receive(:create_stripe_customer) { }
  end
end
