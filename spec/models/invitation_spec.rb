require 'rails_helper'

describe Invitation do
  let(:invitation)  { FactoryGirl.create(:invitation) }



  it { should belong_to(:invitable) }

  it { should have_db_index([:invitable_id, :invitable_type]) }
  it { should have_db_index([:invitable_type, :invitable_id]) }

  it { should belong_to(:sender) }

  describe 'the default scope' do
    let(:valid_invitations)   { FactoryGirl.create_list(:invitation, 2) }
    let(:expired_invitations) { FactoryGirl.create_list(:invitation, 3, :expired) }

    before do
      valid_invitations
      expired_invitations

      expect(Invitation.unscoped).to eq(valid_invitations + expired_invitations)
    end

    it 'does not return expired invitations' do
      expect(Invitation.all).to eq(valid_invitations)
    end
  end

  describe '#is_pin?' do
    context 'when the invitation token is not a pin' do
      it 'should return false' do
        expect(FactoryGirl.create(:invitation).is_pin?).to eq(false)
      end

      it 'should not a token string comprised of 4 digits' do
        expect(invitation.token).not_to match(/^\d{4}$/)
      end
    end

    context 'when the invitation token is a pin' do
      let(:invitation) { FactoryGirl.create(:invitation, :pin) }

      it 'should return true' do
        expect(invitation.is_pin?).to eq(true)
      end

      it 'should have a token string comprised of 4 digits' do
        expect(invitation.token).to match(/^\d{4}$/)
      end
    end
  end

  describe '#expires_at' do
    context 'when the invitation expires' do
      let(:invitation) { FactoryGirl.create(:invitation, expires_at: DateTime.now + 10.minutes) }
    end

    context 'when the :expires_at timestamp for the existing invitation is changed' do
      let(:new_expires_at) { DateTime.now + 20.minutes }
      subject { invitation.update_attribute(:expires_at, new_expires_at) }

      it 'should remove any prior instances of InvitationExpirationJob for the invitation' do
        expect(Resque).to receive(:remove_delayed).with(InvitationExpirationJob, invitation.id)
        subject
      end

      it 'should enqueue an InvitationExpirationJob for the invitation' do
        expect(Resque).to receive(:enqueue_at).with(new_expires_at, InvitationExpirationJob, anything)
        subject
      end
    end
  end

  describe '#create' do
    it 'should set the invitation :token' do
      expect(invitation.token).to_not be_nil
    end

    context 'when :expires_at is not nil' do
      let(:expires_at) { DateTime.now + 10.minutes }
      let(:invitation) { FactoryGirl.create(:invitation, expires_at: expires_at) }

      subject { invitation }

      it 'should not attempt to remove any previous InvitationExpirationJob for the invitation' do
        expect(Resque).not_to receive(:remove_delayed).with(InvitationExpirationJob, invitation.id)
        subject
      end

      it 'should enqueue an InvitationExpirationJob for the invitation' do
        allow(Resque).to receive(:remove_delayed).with(InvitationExpirationJob, anything)
        expect(Resque).to receive(:enqueue_at).with(expires_at, InvitationExpirationJob, anything)
        subject
      end
    end
  end

  describe '#destroy' do
    subject { invitation.destroy }

    context 'when the invitation never expires' do
      it 'should not attempt to remove the InvitationExpirationJob for the invitation' do
        expect(Resque).not_to receive(:remove_delayed).with(InvitationExpirationJob, invitation.id)
        subject
      end
    end

    context 'when the invitation has an :expires_at timestamp' do
      let(:invitation)  { FactoryGirl.create(:invitation, :expired) }

      it 'should remove the InvitationExpirationJob for the invitation' do
        expect(Resque).to receive(:remove_delayed).with(InvitationExpirationJob, invitation.id)
        subject
      end
    end
  end

  describe '#valid?' do
    it 'should allow a nil sender' do
      invitation = FactoryGirl.create(:invitation, sender: nil)
      expect(invitation.valid?).to eq(true)
    end

    it 'should not allow the sender to change' do
      new_sender = FactoryGirl.create(:user)
      invitation.sender = new_sender
      invitation.valid?
      expect(invitation.errors[:sender_id]).to include("can't be changed")
    end

    it 'should not allow the invitable to change' do
      new_invitable = FactoryGirl.create(:user)
      invitation.invitable = new_invitable
      invitation.valid?
      expect(invitation.errors[:invitable_id]).to include("can't be changed")
    end
  end

  describe '#accept' do
    subject { invitation.accept }

    context 'when the invitation has not expired' do
      it 'should set the invitation :accepted_at timestamp' do
        subject
        expect(invitation.accepted_at).to_not be_nil
      end

      it 'should delete the invitation' do
        token = invitation.token
        subject
        expect(Invitation.unscoped.where(token: token).count).to eq(0)
      end
    end

    context 'when the invitation has expired' do
      before { invitation.update_attribute(:expires_at, DateTime.now - 1.hour) }

      it 'should not allow the invitation to be accepted' do
        invitation.accept
        expect(invitation.errors[:base]).to include('expired invitation cannot be accepted')
      end
    end
  end
end
