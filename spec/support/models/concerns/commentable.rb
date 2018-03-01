shared_examples 'commentable' do
  it { should have_many(:comments) }

  describe 'destroying the commentable' do
    let(:comment)  { FactoryGirl.create(:comment, commentable: FactoryGirl.create(:job)) }
    let(:commentable)  { comment.commentable }

    before { expect(commentable.reload.comments.size).to eq(1) }

    subject { commentable.destroy }

    it 'should destroy all of the comments which belong to the destroyed commentable' do
      subject
      expect(commentable.comments.size).to eq(0)
    end
  end
end
