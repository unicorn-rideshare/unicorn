require 'rails_helper'

describe Api::InvitationsController, api: true do
  let(:invitation)  { FactoryGirl.create(:invitation) }

  describe '#show' do
    context 'when the requested id is a valid invitation pin token' do
      let(:invitation) { FactoryGirl.create(:invitation, :pin) }

      subject { get :show, id: invitation.token }

      it 'should return scheduled work orders sorted by :scheduled_start_at asc' do
        subject
        expect(assigns(:invitation)).to eq(invitation)
      end

      it 'returns a 200 status code' do
        subject
        expect(response).to have_http_status(200)
      end

      it 'should render the show template' do
        subject
        expect(response).to render_template('show')
      end
    end
  end
end
