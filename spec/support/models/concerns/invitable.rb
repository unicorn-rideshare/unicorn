shared_examples 'invitable' do
  it { should have_many(:invitations) }

  describe 'creating an invitation' do
    let(:sender) { FactoryGirl.create(:user) }

    subject { invitable.invitations.create(sender: sender) }

    it 'should set the created at time' do
      expect(subject.created_at).to_not be_nil
    end

    it 'should set the updated at time' do
      expect(subject.updated_at).to_not be_nil
    end

    it 'should invoke #invitation_received on the invitation instance' do
      expect(invitable).to receive(:invitation_received).exactly(1).times.and_call_original
      subject
    end
  end

  describe 'destroying the invitable' do
    let(:invite)     { FactoryGirl.create(:invitation, invitable: FactoryGirl.create(:user)) }
    let(:invitable)  { invite.invitable }

    before { expect(invitable.reload.invitations.size).to eq(1) }

    subject { invitable.destroy }

    it 'should destroy all of the invites which belong to the destroyed invitable' do
      subject
      expect(invitable.invitations.size).to eq(0)
    end
  end
end
