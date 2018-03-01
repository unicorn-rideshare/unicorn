require 'rails_helper'

describe InvitationExpirationJob do
  describe '.perform' do
    subject { InvitationExpirationJob.perform(invitation.id) }

    context 'when the invitation has expired' do
      let(:invitation) { FactoryGirl.create(:invitation, :expired) }

      it 'destroys the invitation' do
        token = invitation.token
        subject
        expect(Invitation.unscoped.where(token: token).count).to eq(0)
      end
    end
  end
end
