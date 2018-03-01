shared_examples 'authenticable' do
  it { should have_many(:tokens) }

  describe 'destroying the authenticable' do
    let(:token)  { FactoryGirl.create(:token) }
    let(:authenticable)  { token.authenticable }

    before { expect(authenticable.reload.tokens.size).to eq(1) }

    subject { authenticable.destroy }

    it 'should destroy all of the tokens which belong to the destroyed authenticable' do
      subject
      expect(authenticable.tokens.size).to eq(0)
    end
  end
end
