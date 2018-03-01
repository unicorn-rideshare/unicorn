require 'rails_helper'

describe Api::CheckinsController, api: true do
  let(:checkin) { FactoryGirl.create :checkin, locatable: user }
  let(:user)    { FactoryGirl.create(:user) }

  before { sign_in user }

  it_behaves_like 'api_controller', :index, :destroy do
    let(:resource) { checkin }
  end

  describe 'POST create' do
    describe 'with valid params' do
      subject { post :create, latitude: 33.7358267, longitude: -84.3893847, checkin_at: '2014-06-01T03:40:06+00:00' }

      it 'creates a new Checkin' do
        expect { subject }.to change(Checkin, :count).by(1)
      end

      it 'assigns a newly created checkin as @checkin' do
        subject
        expect(assigns(:checkin)).to be_a(Checkin)
        expect(assigns(:checkin)).to be_persisted
      end

      it 'assigns the user as the :locatable on the created checkin' do
        subject
        expect(assigns(:checkin).locatable).to eq(user)
      end

      it 'returns a 201 status code' do
        subject
        expect(response).to have_http_status(201)
      end

      it 'should render the show template' do
        subject
        expect(response).to render_template('show')
      end
    end

    describe 'with invalid params' do
      subject { post :create }

      it 'assigns a newly created but unsaved checkin as @checkin' do
        subject
        expect(assigns(:checkin)).to be_a_new(Checkin)
      end

      it 'returns a 422 status code' do
        subject
        expect(response).to have_http_status(422)
      end
    end
  end

end
