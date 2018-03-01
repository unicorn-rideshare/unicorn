shared_examples 'attachable' do
  it { should have_many(:attachments) }

  describe 'destroying the attachable' do
    let(:attachment)  { FactoryGirl.create(:attachment) }
    let(:attachable)  { attachment.attachable }

    before { expect(attachable.reload.attachments.size).to eq(1) }

    subject { attachable.destroy }

    it 'should destroy all of the attachments which belong to the destroyed attachable' do
      subject
      expect(attachable.attachments.size).to eq(0)
    end
  end
end
