shared_examples 'notifiable' do
  it { should have_many(:notifications) }
end
