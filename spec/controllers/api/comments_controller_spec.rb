require 'rails_helper'

describe Api::CommentsController, api: true do
  let(:work_order) { FactoryGirl.create(:work_order) }
  let(:comment) { FactoryGirl.create(:comment, commentable: work_order) }
  let(:user) { work_order.company.user }

  before { sign_in user }

  describe '#index' do
    before do
      get :index, work_order_id: work_order.id
    end

    it_behaves_like 'a successful index request'
  end

  describe 'POST create' do
    describe 'with valid params' do
      subject { post :create, work_order_id: work_order.id, body: 'This is a comment.' }

      it 'creates a new comment' do
        expect { subject }.to change(Comment, :count).by(1)
      end

      it 'assigns a newly created comment as @comment' do
        subject
        expect(assigns(:comment)).to be_a(Comment)
        expect(assigns(:comment)).to be_persisted
      end

      it 'assigns the newly created comment user' do
        subject
        expect(assigns(:comment).user).to eq(user)
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
  end
end
