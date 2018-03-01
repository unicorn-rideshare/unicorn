shared_examples 'api_controllers#show' do
  describe 'GET show' do
    context 'user is signed in' do
      before do
        sign_in user
        get :show, (resource_params rescue { id: resource.id })
      end

      it 'assigns all resource collection' do
        expect(assigns(resource_name)).to eq(resource)
      end

      it { should respond_with(:ok) }
      it { should render_template('show') }
    end

    context 'another user is signed in' do
      let(:other_user) { FactoryGirl.create(:user) }

      before { sign_in other_user }

      it 'should restrict access' do
        get :show, (resource_params rescue { id: resource.id })
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
