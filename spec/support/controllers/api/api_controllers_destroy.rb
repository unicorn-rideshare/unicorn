shared_examples 'api_controllers#destroy' do
  describe 'DELETE destroy' do
    context 'user is signed in' do
      before do
        resource
        sign_in user
        delete :destroy, (resource_params rescue { id: resource.id })
      end

      it 'destroys the requested resource' do
        expect(resource.class.all).to_not include(resource)
      end

      it { should respond_with(:no_content) }
      it { expect(response.body).to eq('') }
    end

    context 'another user is signed in' do
      let(:other_user) { FactoryGirl.create(:user) }

      before { sign_in other_user }

      it 'should restrict access' do
        delete :destroy, (resource_params rescue { id: resource.id })
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
