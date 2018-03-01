require 'rails_helper'

describe Comment do
  it_behaves_like 'attachable'
  it_behaves_like 'notifiable'


  it { should belong_to(:commentable) }

  it { should belong_to(:user) }
  it { should validate_presence_of(:user) }

  describe '#create' do
    it 'should set the created at time' do
      comment = FactoryGirl.create(:comment)
      expect(comment.created_at).to_not be_nil
    end
  end

  describe '#update' do
    it 'should not update the comment' do
      comment = FactoryGirl.create(:comment)
      expect { comment.save! }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end
end
