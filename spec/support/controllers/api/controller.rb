shared_examples 'api_controller' do |*actions|
  let(:resource_name) { resource.class.to_s.demodulize.underscore.to_sym }

  it_behaves_like 'api_controllers#index' if actions.include?(:index)
  it_behaves_like 'api_controllers#show' if actions.include?(:show)
  it_behaves_like 'api_controllers#destroy' if actions.include?(:destroy)
end

shared_context 'a successful index request' do
  it 'returns an OK (200) status code' do
    expect(response.status).to eq(200)
  end

  it 'renders the index template' do
    expect(response).to render_template('index')
  end
end
