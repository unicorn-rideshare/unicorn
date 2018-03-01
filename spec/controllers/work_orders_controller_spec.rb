require 'rails_helper'

describe WorkOrdersController do
  let(:company)       { FactoryGirl.create(:company) }
  let(:customer)      { FactoryGirl.create(:customer, company: company) }
  let(:work_order)    { FactoryGirl.create(:work_order, :scheduled, :with_provider, company: company, customer: customer) }

  before do
    work_order.config = { customer_communications: { exposes_status_publicly: true } }
    work_order.save
  end

  shared_examples 'communications configuration :exposes_status_publicly' do
    subject { get :show, id: work_order.id.to_s }

    it 'should assign the requested work order' do
      subject
      expect(assigns(:work_order)).to eq(work_order)
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

  context 'when the company communications configuration :exposes_status_publicly' do
    before do
      work_order.config = { customer_communications: { exposes_status_publicly: true } }
      work_order.save
    end

    it_should_behave_like 'communications configuration :exposes_status_publicly'
  end

  context 'when the customer communications configuration :exposes_status_publicly' do
    before do
      work_order.config = { customer_communications: { exposes_status_publicly: true } }
      work_order.save
    end

    it_should_behave_like 'communications configuration :exposes_status_publicly'
  end

  context 'when the work order customer communications configuration :exposes_status_publicly' do
    before do
      work_order.config = { customer_communications: { exposes_status_publicly: true } }
      work_order.save
    end

    it_should_behave_like 'communications configuration :exposes_status_publicly'
  end

  context 'when the work order customer communications configuration :exposes_status_publicly is false' do
    before do
      work_order.config = { customer_communications: { exposes_status_publicly: false } }
      work_order.save
    end

    subject { get :show, id: work_order.id.to_s }

    it 'returns a 403 status code' do
      subject
      expect(response).to have_http_status(403)
    end
  end
end
