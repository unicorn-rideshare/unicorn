require 'rails_helper'

describe Api::WorkOrdersController, api: true do
  let(:user)        { FactoryGirl.create(:user) }
  let(:other_user)  { FactoryGirl.create(:user) }

  before do
    sign_in user
  end

  context 'when the requesting user is unaffiliated with a company' do
    describe '#create' do
      context 'with valid params' do
        context 'with an explicitly nil company id' do
          subject { post :create, company_id: nil }

          it 'should create the work order' do
            expect(subject).to have_http_status(:created)
          end
        end

        context 'with an explicitly nil customer id' do
          subject { post :create, customer_id: nil }

          it 'should create the work order' do
            expect(subject).to have_http_status(:created)
          end
        end
      end
    end
  end

  context 'when the requesting user is a provider on the work order' do
    let(:company)      { FactoryGirl.create(:company) }
    let(:customer)     { FactoryGirl.create(:customer, company: company) }
    let(:provider)     { FactoryGirl.create(:provider, user: user, company: company) }
    let(:work_order)   { FactoryGirl.create(:work_order, company: company, customer: customer) }

    before do
      work_order.work_order_providers_attributes = [ { provider_id: provider.id } ]
      provider.user.add_role(:provider, work_order)
    end

    it_behaves_like 'api_controller', :index, :show do
      let(:resource) { work_order }
    end

    describe '#index' do
      context 'when no query params are provided' do
        subject { get :index }

        it 'should return scheduled work orders sorted by :scheduled_start_at asc (nulls last)' do
          subject
          expect(assigns(:work_orders)).to eq([work_order])
        end

        it 'returns a 200 status code' do
          subject
          expect(response).to have_http_status(200)
        end

        it 'should render the index template' do
          subject
          expect(response).to render_template('index')
        end
      end

      context 'when query params are provided' do
        subject { get :index, params }

        context 'when a status param is provided' do
          let(:scheduled_work_orders) do
            FactoryGirl.create_list(:work_order, 3, :scheduled,
                                    company: company,
                                    customer: customer,
                                    provider: provider)
          end

          let(:canceled_work_orders) do
            FactoryGirl.create_list(:work_order, 2, :canceled,
                                    company: company,
                                    customer: customer,
                                    provider: provider)
          end

          before do
            scheduled_work_orders.each do |wo|
              provider.user.add_role(:provider, wo)  # HACK
            end

            canceled_work_orders.each do |wo|
              provider.user.add_role(:provider, wo)  # HACK
            end
          end

          context 'when the status param is "scheduled"' do
            let(:params) { { status: 'scheduled' } }

            it 'should return all scheduled work orders sorted by :scheduled_start_at asc (nulls last)' do
              subject
              expect(assigns(:work_orders)).to eq(scheduled_work_orders)
            end
          end

          context 'when the status param is "canceled"' do
            let(:params) { { status: 'canceled' } }

            it 'should return all canceled work orders sorted by :scheduled_start_at asc (nulls last)' do
              subject
              expect(assigns(:work_orders).to_a).to eq(canceled_work_orders.reverse)
            end
          end

          context 'when the status param is comma-delimited "scheduled,canceled"' do
            let(:params) { { status: 'scheduled,canceled' } }

            it 'should return all canceled work orders sorted by :scheduled_start_at asc (nulls last)' do
              subject
              expect(assigns(:work_orders).to_a).to eq(scheduled_work_orders + canceled_work_orders)
            end
          end
        end

        context 'when a date_range param is provided' do
          let(:now) { Time.utc(2014, 8, 1) }

          let(:work_order1) do
            FactoryGirl.create :work_order,
                               :with_provider,
                               :scheduled,
                               company: company,
                               customer: customer,
                               description: 'Customer has a filthy house...',
                               provider: provider,
                               scheduled_start_at: customer.contact.time_zone.local(2014, 8, 10, 12)
          end

          let(:work_order2) do
            FactoryGirl.create :work_order,
                               :with_provider,
                               :scheduled,
                               company: company,
                               customer: customer,
                               description: 'Monthly cleaning as expected',
                               provider: provider,
                               scheduled_start_at: customer.contact.time_zone.local(2014, 8, 11, 12)
          end

          let(:work_order3) do
            FactoryGirl.create :work_order,
                               :with_provider,
                               :scheduled,
                               company: company,
                               customer: customer,
                               description: 'Monthly cleaning as expected',
                               provider: provider,
                               scheduled_start_at: customer.contact.time_zone.local(2014, 8, 13, 12)
          end

          before do
            Timecop.travel(now)
            work_order1
            work_order2
            work_order3
          end

          context 'when the date_range parameter only specifies an "on or after" date' do
            let(:params) { { date_range: '2014-08-10..' } }

            it 'should return all scheduled work orders on or after the given date sorted by :scheduled_start_at asc (nulls last)' do
              subject
              expect(assigns(:work_orders).to_a).to eq([work_order1, work_order2, work_order3])
            end
          end

          context 'when the date_range parameter only specifies an "on or before" date' do
            let(:params) { { date_range: '..2014-08-10' } }

            it 'should return all scheduled work orders on or before the given date sorted by :scheduled_start_at asc (nulls last)' do
              subject
              expect(assigns(:work_orders).to_a).to eq([work_order1])
            end
          end

          context 'when the date_range parameter specifies an "on or after" date and an "on or before" date' do
            context 'when the date_range parameter specifies an "on or after" date not equal to the "on or before" date' do
              let(:params) { { date_range: '2014-08-11..2014-08-12' } }

              it 'should return all scheduled work orders on or after the first given date, and on or before the second given date sorted by :scheduled_start_at asc (nulls last)' do
                subject
                expect(assigns(:work_orders).to_a).to eq([work_order2])
              end
            end

            context 'when the date_range parameter specifies an "on or after" date equal to the "on or before" date' do
              let(:params) { { date_range: '2014-08-11..2014-08-11' } }

              it 'should return all scheduled work orders on or after the first given date, and on or before the second given date sorted by :scheduled_start_at asc (nulls last)' do
                subject
                expect(assigns(:work_orders).to_a).to eq([work_order2])
              end
            end

          end
        end

        context 'when a work order is part of a route' do
          before do
            poa = FactoryGirl.create(:provider_origin_assignment, start_date: Date.today, end_date: Date.today)
            r = FactoryGirl.create(:route, provider_origin_assignment: poa, date: Date.today)
            r.legs.create(work_order: work_order)
          end

          context 'when the exclude_routes parameter is true' do
            let(:params) { { exclude_routes: 'true' } }

            it 'should not return the routed work order' do
              subject
              expect(assigns(:work_orders)).to eq([])
            end
          end
        end
      end
    end

    describe '#create' do
      context 'with valid params' do
        let(:params) { { company_id: company.id,
                         customer_id: customer.id,
                         status: 'awaiting_schedule',
                         preferred_scheduled_start_date: (DateTime.now + 2.days).iso8601 } }

        subject { post :create, params }

        it 'does not create a new WorkOrder' do
          expect { subject }.to change(WorkOrder, :count).by(0)
        end

        it 'returns a 403 status code' do
          subject
          expect(response).to have_http_status(403)
        end
      end

      describe 'with invalid params' do

      end
    end

    describe '#update' do
      describe 'with valid params' do
        let(:params) { { company_id: company.id, customer_id: customer.id } }
        subject { put :update, params.merge(id: work_order.id) }

        it 'updates the requested work order' do
          expect_any_instance_of(WorkOrder).to receive(:update)
          subject
        end

        it 'assigns the requested work_order as @work_order' do
          subject
          expect(assigns(:work_order)).to eq(work_order)
        end

        it 'returns a 204 status code' do
          subject
          expect(response).to have_http_status(204)
        end

        it 'response body is empty' do
          subject
          expect(response.body).to eq('')
        end

        context 'another user is signed in' do
          before { sign_in other_user }

          it 'should restrict access' do
            expect(subject).to have_http_status(:forbidden)
          end
        end

        context 'when the request contains a :work_order_providers parameter' do
          let(:confirmed_at)  { DateTime.now }
          let(:provider) { FactoryGirl.create(:provider, company: company, user: user) }
          let(:work_order_providers) { [{ provider_id: provider.id, confirmed_at: confirmed_at.utc.iso8601 }] }
          let(:params) { { id: work_order.id, work_order_providers: work_order_providers } }

          subject { put :update, params }

          # FIXME-- failing test
          xit 'returns a 204 status code' do
            subject
            expect(response).to have_http_status(204)
          end

          # FIXME-- failing test
          xit 'sets the confirmed_at timestamp for the work order provider' do
            subject
            expect(work_order.reload.work_order_providers.first.confirmed_at).to_not be_nil
          end
        end

        context 'when the request contains :gtins_delivered' do
          let(:product1) { FactoryGirl.create(:product, company: work_order.company) }
          let(:product2) { FactoryGirl.create(:product, company: work_order.company) }
          let(:product3) { FactoryGirl.create(:product, company: work_order.company) }

          before do
            [product1, product2, product3].each do |product|
              work_order.items_ordered << product
            end

            work_order.items_ordered << product1
          end

          subject { put :update, params.merge(id: work_order.id) }

          context 'when the request does not contain a :gtins_rejected param' do
            before { params.merge!(gtins_delivered: [product1.gtin, product1.gtin]) }

            it 'returns a 422 status code' do
              subject
              expect(response).to have_http_status(422)
            end
          end

          context 'when the work order has items that have not yet been delivered' do
            context 'when the :gtins_delivered param contains more than one gtin' do
              context 'when the :gtins_delivered param contains 2 or more unique gtins' do
                before do
                  params.merge!(gtins_delivered: [product1.gtin, product2.gtin, product1.gtin], gtins_rejected: [])
                end

                it 'assigns the requested work order as @work_order' do
                  subject
                  expect(assigns(:work_order)).to eq(work_order)
                end

                it 'returns a 204 status code' do
                  subject
                  expect(response).to have_http_status(204)
                end

                it 'response body is empty' do
                  subject
                  expect(response.body).to eq('')
                end

                it 'updates the :items_delivered to be the items as specified by the :gtins_delivered param' do
                  subject
                  expect(work_order.reload.items_delivered.to_a).to eq([product1, product2, product1].sort_by { |p| p.gtin })
                  expect(work_order.reload.items_rejected).to eq([])
                end
              end

              context 'when the :gtins_delivered param contains only a single unique gtin' do
                before do
                  params.merge!(gtins_delivered: [product1.gtin, product1.gtin], gtins_rejected: [product2.gtin])
                end

                it 'assigns the requested work order as @work_order' do
                  subject
                  expect(assigns(:work_order)).to eq(work_order)
                end

                it 'returns a 204 status code' do
                  subject
                  expect(response).to have_http_status(204)
                end

                it 'response body is empty' do
                  subject
                  expect(response.body).to eq('')
                end

                it 'updates the :items_delivered to be the items as specified by the :gtins_delivered param' do
                  subject
                  expect(work_order.reload.items_delivered).to eq([product1, product1])
                  expect(work_order.reload.items_rejected).to eq([product2])
                end
              end
            end
          end

          context 'when the request contains delivered items that were not ordered' do
            let(:invalid_item_delivered) { FactoryGirl.create(:product, company: work_order.company) }

            before do
              work_order.items_delivered = work_order.items_ordered.shuffle
            end

            context 'when the :gtins_delivered param contains more than one gtin' do
              before do
                params.merge!(gtins_delivered: [product1.gtin, product2.gtin, invalid_item_delivered.gtin], gtins_rejected: [])
              end

              it 'assigns the requested work order as @work_order' do
                subject
                expect(assigns(:work_order)).to eq(work_order)
              end

              it 'returns a 422 status code' do
                subject
                expect(response).to have_http_status(422)
              end

              it 'response body to contain errors' do
                subject
                expected = {
                    errors: {
                        items_delivered: ["items delivered must be included in items ordered"],
                        items_delivered_and_rejected: ["items delivered and rejected must be included in items ordered"]
                    }
                }.to_json
                expect(response.body).to eq(expected)
              end
            end
          end

          context 'when the work order contains rejected items' do
            before { work_order.items_rejected << product1 }

            context 'when the :gtins_rejected param contains more than one gtin' do
              before do
                params.merge!(gtins_delivered: [product1.gtin, product2.gtin, product1.gtin], gtins_rejected: [])
              end

              it 'assigns the requested work order as @work_order' do
                subject
                expect(assigns(:work_order)).to eq(work_order)
              end

              it 'returns a 204 status code' do
                subject
                expect(response).to have_http_status(204)
              end

              it 'response body is empty' do
                subject
                expect(response.body).to eq('')
              end

              it 'updates the :items_delivered to be the items as specified by the :gtins_delivered param' do
                subject
                expect(work_order.reload.items_delivered.to_a).to eq([product1, product1, product2].sort_by { |p| p.gtin })
                expect(work_order.reload.items_rejected).to eq([])
              end
            end
          end
        end

        context 'when the request contains :gtins_rejected' do
          let(:product1) { FactoryGirl.create(:product, company: work_order.company) }
          let(:product2) { FactoryGirl.create(:product, company: work_order.company) }
          let(:product3) { FactoryGirl.create(:product, company: work_order.company) }

          before do
            [product1, product2, product3].each do |product|
              work_order.items_ordered << product
            end

            work_order.items_ordered << product1
          end

          subject { put :update, params.merge(id: work_order.id) }

          context 'when the request does not contain a :gtins_delivered param' do
            before { params.merge!(gtins_rejected: [product1.gtin, product1.gtin]) }

            it 'returns a 422 status code' do
              subject
              expect(response).to have_http_status(422)
            end
          end

          context 'when the work order has items that have been delivered' do
            before do
              work_order.items_delivered << work_order.items_ordered[0]
              work_order.items_delivered << work_order.items_ordered[1]
              work_order.items_delivered << work_order.items_ordered[3]

              expect(work_order.items_ordered.count).to eq(4)
              expect(work_order.items_delivered.count).to eq(3)
            end

            context 'when the work order has items that have not yet been rejected' do
              context 'when the :gtins_rejected param contains more than one gtin' do
                before { params.merge!(gtins_delivered: [product2.gtin], gtins_rejected: [product1.gtin, product1.gtin]) }

                it 'assigns the requested work order as @work_order' do
                  subject
                  expect(assigns(:work_order)).to eq(work_order)
                end

                it 'returns a 204 status code' do
                  subject
                  expect(response).to have_http_status(204)
                end

                it 'response body is empty' do
                  subject
                  expect(response.body).to eq('')
                end

                it 'updates the :items_delivered to be the item specified by the :gtins_delivered param' do
                  subject
                  expect(work_order.reload.items_delivered.to_a).to eq([product2])
                end

                it 'updates the :items_rejected to be the item as specified by the :gtins_rejected param' do
                  subject
                  expect(work_order.reload.items_rejected.to_a).to eq([product1, product1])
                end
              end
            end

            context 'when the request contains an invalid combination of :gtins_delivered and :gtins_rejected' do
              before do
                params.merge!(gtins_delivered: [product1.gtin, product2.gtin], gtins_rejected: [product1.gtin, product2.gtin])
              end

              it 'assigns the requested work order as @work_order' do
                subject
                expect(assigns(:work_order)).to eq(work_order)
              end

              it 'returns a 422 status code' do
                subject
                expect(response).to have_http_status(422)
              end

              it 'response body to contain errors' do
                subject
                expected = {
                    errors: {
                        items_delivered_and_rejected: ["items delivered and rejected must be included in items ordered"]
                    }
                }.to_json
                expect(response.body).to eq(expected)
              end
            end
          end

          context 'when the request contains rejected items that were not ordered' do
            let(:invalid_item_rejected) { FactoryGirl.create(:product, company: work_order.company) }

            context 'when the :gtins_rejected param contains more than one gtin' do
              before do
                params.merge!(gtins_delivered: [], gtins_rejected: [work_order.items_ordered.first.gtin, work_order.items_ordered.second.gtin, invalid_item_rejected.gtin])
              end

              it 'assigns the requested work order as @work_order' do
                subject
                expect(assigns(:work_order)).to eq(work_order)
              end

              it 'returns a 422 status code' do
                subject
                expect(response).to have_http_status(422)
              end

              it 'response body to contain errors' do
                subject
                expected = {
                    errors: {
                        items_rejected: ["items rejected must be included in items ordered"],
                        items_delivered_and_rejected: ["items delivered and rejected must be included in items ordered"]
                    }
                }.to_json
                expect(response.body).to eq(expected)
              end
            end
          end
        end

        context 'when the request contains an :accept_invitation parameter' do
          context 'when there is a standalone provider with a pending work_order_provider invitation' do
            let(:standalone_provider)  { FactoryGirl.create(:provider, user: user, company: nil) }

            before do
              allow(Resque).to receive(:enqueue).with(GeocodeContactJob, anything) { }
              allow(Resque).to receive(:enqueue).with(SendInvitationJob, anything)
              allow(Resque).to receive(:enqueue).with(PushWorkOrderProviderAddedJob, anything, anything)
              allow(Resque).to receive(:enqueue).with(PushNotificationJob, anything, anything)

              work_order.work_order_providers.create(provider: standalone_provider)
              work_order.work_order_providers.first.invitations.create
              expect(work_order.reload.work_order_providers.first.invitations.size).to eq(1)
            end

            subject { put :update, id: work_order.id, invitation_token: work_order.work_order_providers.first.invitations.first.token }

            it 'returns a 204 status code' do
              subject
              expect(response).to have_http_status(204)
            end

            it 'accepts the invitation on behalf of the work order provider' do
              expect_any_instance_of(Invitation).to receive(:accept).and_call_original
              subject
              expect(work_order.reload.work_order_providers.first.invitations.size).to eq(0)
            end
          end
        end
      end

      describe 'with invalid params' do
        subject { put :update, id: work_order.id, company_id: nil, customer_id: nil }

        it 'assigns the work_order as @work_order' do
          subject
          expect(assigns(:work_order)).to eq(work_order)
        end

        it 'returns a 422 status code' do
          subject
          expect(response).to have_http_status(422)
        end

        it 'response body to contain errors' do
          subject
          expected = {
              errors: {
                  company_id: ["can't be changed"],
                  customer_id: ["can't be changed"]
              }
          }.to_json
          expect(response.body).to eq(expected)
        end
      end
    end
  end

  context 'when the requesting user is a supervisor on the job to which the work order belongs' do
    let(:company) { FactoryGirl.create(:company) }
    let(:customer) { FactoryGirl.create(:customer, company: company) }
    let(:provider) { FactoryGirl.create(:provider, company: company, user: user) }
    let(:job) { FactoryGirl.create(:job, company: company, customer: customer) }
    let(:work_order) { FactoryGirl.create(:work_order, company: company, customer: customer, job: job) }

    before do
      allow(Resque).to receive(:enqueue).with(anything, anything)
      allow(Resque).to receive(:enqueue).with(anything, anything, anything)
      allow(Resque).to receive(:remove_delayed).with(anything, anything)

      job.supervisors = [provider]
    end

    describe '#update' do
      describe 'with valid params' do
        let(:params) { { company_id: company.id, customer_id: customer.id } }
        subject { put :update, params.merge(id: work_order.id) }

        it 'updates the requested work order' do
          expect_any_instance_of(WorkOrder).to receive(:update)
          subject
        end

        it 'assigns the requested work_order as @work_order' do
          subject
          expect(assigns(:work_order)).to eq(work_order)
        end

        it 'returns a 204 status code' do
          subject
          expect(response).to have_http_status(204)
        end

        it 'response body is empty' do
          subject
          expect(response.body).to eq('')
        end

        context 'another user is signed in' do
          before { sign_in other_user }

          it 'should restrict access' do
            expect(subject).to have_http_status(:forbidden)
          end
        end

        context 'when the request contains :work_order_providers' do
          let(:added_provider) { FactoryGirl.create(:provider, :with_user, company: company) }

          before do
            params.merge!(work_order_providers: [ { provider_id: added_provider.id } ])
          end

          it 'returns a 204 status code' do
            subject
            expect(response).to have_http_status(204)
          end

          # FIXME-- failing test
          xit 'updates the work order providers' do
            subject
            expect(assigns(:work_order).providers).to eq([added_provider])
          end
        end

        context 'when the request contains a :status' do
          context 'when the :status is canceled' do
            before do
              params.merge!(status: 'canceled')
            end

            it 'should remove the delayed WorkOrderEmailJob for the canceled work order' do
              allow(Resque).to receive(:remove_delayed).with(anything, anything)
              expect(Resque).to receive(:remove_delayed).with(WorkOrderEmailJob, work_order.id, :scheduled_confirmation)
              expect(Resque).to receive(:remove_delayed).with(WorkOrderEmailJob, work_order.id, :reminder)
              expect(Resque).to receive(:remove_delayed).with(WorkOrderEmailJob, work_order.id, :morning_of_reminder)
              expect(Resque).to receive(:enqueue).with(WorkOrderCanceledJob, work_order.id)
              subject { put :update, params.merge(id: work_order.id) }
            end
          end
        end
      end

      describe 'with invalid params' do
        context 'when the params do not contain an invalid status' do
          subject { put :update, id: work_order.id, company_id: nil, customer_id: nil }

          it 'assigns the work_order as @work_order' do
            subject
            expect(assigns(:work_order)).to eq(work_order)
          end

          it 'returns a 204 status code' do
            subject
            expect(response).to have_http_status(422)
          end

          it 'response body to contain errors' do
            subject
            expected = {
                errors: {
                    company_id: ["can't be changed"],
                    customer_id: ["can't be changed"]
                }
            }.to_json
            expect(response.body).to eq(expected)
          end
        end

        context 'when the params contain an invalid status' do
          subject { put :update, id: work_order.id, company_id: nil, customer_id: nil, status: 'invalid_status' }

          it 'assigns the work_order as @work_order' do
            subject
            expect(assigns(:work_order)).to eq(work_order)
          end

          it 'returns a 204 status code' do
            subject
            expect(response).to have_http_status(422)
          end

          it 'response body to contain errors' do
            subject
            expected = {
                errors: {
                    status: ["is invalid", "is not included in the list"]
                }
            }.to_json
            expect(response.body).to eq(expected)
          end
        end
      end
    end
  end

  context 'when the requesting user is an admin of the work order company' do
    let(:company)     { FactoryGirl.create(:company, user: user) }
    let(:customer)    { FactoryGirl.create(:customer, company: company) }
    let(:work_order)  { FactoryGirl.create(:work_order, company: company, customer: customer) }

    before do
      sign_in(user)
    end

    it_behaves_like 'api_controller', :index, :show, :destroy do
      let(:resource) { work_order }
    end

    describe '#create' do
      context 'with valid params' do
        let(:provider)  { FactoryGirl.create(:provider, :with_user, company: company) }
        let(:params) { { company_id: company.id,
                         customer_id: customer.id,
                         preferred_scheduled_start_date: (DateTime.now + 2.days).iso8601,
                         work_order_providers: [ { provider_id: provider.id } ] } }

        before do
          user.add_role(:admin, company)
        end

        subject { post :create, params }

        it 'creates a new WorkOrder' do
          expect { subject }.to change(WorkOrder, :count).by(1)
        end

        it 'assigns a newly created work_order as @work_order' do
          subject
          expect(assigns(:work_order)).to be_a(WorkOrder)
          expect(assigns(:work_order)).to be_persisted
        end

        it 'assigns the newly created work_order company' do
          subject
          expect(assigns(:work_order).company).to eq(company)
        end

        it 'returns a 201 status code' do
          subject
          expect(response).to have_http_status(201)
        end

        # FIXME-- failing test
        xit 'should render the show template' do
          subject
          expect(response).to render_template('show')
        end

        # FIXME-- failing test
        xit 'should create a new work_order_provider' do
          subject
          expect(assigns(:work_order).work_order_providers.count).to eq(1)
        end

        # FIXME-- failing test
        xit 'should add the :provider role to each user that is a work_order_provider' do
          expect { subject }.to change { provider.user.roles.count }.by(1)
          expect(provider.user.has_role?(:provider, assigns(:work_order))).to eq(true)
        end

        context 'when the request contains a :scheduled_start_at' do
          let(:params) { { company_id: company.id, customer_id: customer.id, status: 'scheduled', scheduled_start_at: (DateTime.now + 10.days).iso8601 } }

          it 'should enqueue a WorkOrderScheduledJob' do
            allow(Resque).to receive(:enqueue).with(anything, anything)
            expect(Resque).to receive(:enqueue).with(WorkOrderScheduledJob, anything)
            post :create, params
          end
        end

        context 'when the request contains :gtins_ordered' do
          let(:products)  { FactoryGirl.create_list(:product, 3, company: work_order.company) }
          let(:params)    { { company_id: company.id, customer_id: customer.id, preferred_scheduled_start_date: Date.today.iso8601 } }

          context 'when the :gtins_ordered param contains more than one gtin' do
            before do
              params.merge!(gtins_ordered: [products.last.gtin, products.first.gtin, products.first.gtin])
            end

            it 'returns a 201 status code' do
              subject
              expect(response).to have_http_status(201)
            end

            it 'sets the :items_ordered on the work order' do
              subject
              expect(assigns(:work_order).reload.items_ordered.to_a).to eq([products.last, products.first, products.first].sort_by { |p| p.gtin })
            end
          end
        end

        context 'when the request contains a :route_id' do
          let(:provider_origin_assignment)  { FactoryGirl.create(:provider_origin_assignment, provider: provider, start_date: Date.today, end_date: Date.today) }
          let(:route)                       { FactoryGirl.create(:route, provider_origin_assignment: provider_origin_assignment, date: Date.today) }

          subject { post :create, params.merge(route_id: route.id) }

          it 'returns a 201 status code' do
            subject
            expect(response).to have_http_status(201)
          end

          it 'assigns the new work order to a route leg' do
            subject
            expect(assigns(:work_order).reload.route_leg.route).to eq(route)
          end
        end

        context 'when the request contains a :job_id' do
          let(:job)  { FactoryGirl.create(:job, company: company) }

          subject { post :create, params.merge(job_id: job.id) }

          it 'returns a 201 status code' do
            subject
            expect(response).to have_http_status(201)
          end

          it 'associate the work order with the job' do
            subject
            expect(assigns(:work_order).reload.job_id).to eq(job.id)
          end
        end

        context 'when the request contains a :config parameter' do
          let(:config)  { { } }

          subject { post :create, params.merge(config: config) }

          context 'when the :config contains :components' do
            let(:components) { [{ component: 'PackingSlip' }] }

            before { config[:components] = components }

            it 'returns a 201 status code' do
              subject
              expect(response).to have_http_status(201)
            end

            it 'sets the components in the work order config' do
              subject
              expect(assigns(:work_order).reload.config[:components]).to eq([{"component" => "PackingSlip"}])
            end
          end
        end
      end

      describe 'with invalid params' do
      end
    end

    describe '#call' do
      before do
        allow(TwilioService).to receive(:verify_signature) { true }
      end

      subject { post :call, id: work_order.id }

      it 'returns a 200 status code' do
        subject
        expect(response).to have_http_status(200)
      end
    end

    describe '#update' do
      describe 'with valid params' do
        let(:params) { { company_id: company.id, customer_id: customer.id } }
        subject { put :update, params.merge(id: work_order.id) }

        it 'updates the requested work order' do
          expect_any_instance_of(WorkOrder).to receive(:update)
          subject
        end

        it 'assigns the requested work_order as @work_order' do
          subject
          expect(assigns(:work_order)).to eq(work_order)
        end

        it 'returns a 204 status code' do
          subject
          expect(response).to have_http_status(204)
        end

        it 'response body is empty' do
          subject
          expect(response.body).to eq('')
        end

        context 'another user is signed in' do
          before { sign_in other_user }

          it 'should restrict access' do
            expect(subject).to have_http_status(:forbidden)
          end
        end

        context 'when the request contains a :status' do
          context 'when the :status is canceled' do
            before do
              params.merge!(status: 'canceled')
            end

            it 'should remove the delayed WorkOrderEmailJob for the canceled work order' do
              allow(Resque).to receive(:remove_delayed).with(anything, anything)
              expect(Resque).to receive(:remove_delayed).with(WorkOrderEmailJob, work_order.id, :scheduled_confirmation)
              expect(Resque).to receive(:remove_delayed).with(WorkOrderEmailJob, work_order.id, :reminder)
              expect(Resque).to receive(:remove_delayed).with(WorkOrderEmailJob, work_order.id, :morning_of_reminder)
              expect(Resque).to receive(:enqueue).with(WorkOrderCanceledJob, work_order.id)
              subject { put :update, params.merge(id: work_order.id) }
            end
          end

          context 'when the :status is en_route' do
            let(:work_order) { FactoryGirl.create(:work_order, :scheduled, company: company, customer: customer) }

            before do
              params.merge!(status: 'en_route')
            end

            it 'should enqueue a WorkOrderProviderEnRouteJob for the work order' do
              expect(Resque).to receive(:enqueue).with(WorkOrderProviderEnRouteJob, work_order.id)
              subject { put :update, params.merge(id: work_order.id) }
            end
          end
        end
      end

      describe 'with invalid params' do
        context 'when the params do not contain an invalid status' do
          subject { put :update, id: work_order.id, company_id: nil, customer_id: nil }

          it 'assigns the work_order as @work_order' do
            subject
            expect(assigns(:work_order)).to eq(work_order)
          end

          it 'returns a 204 status code' do
            subject
            expect(response).to have_http_status(422)
          end

          it 'response body to contain errors' do
            subject
            expected = {
                errors: {
                    company_id: ["can't be changed"],
                    customer_id: ["can't be changed"]
                }
            }.to_json
            expect(response.body).to eq(expected)
          end
        end

        context 'when the params contain an invalid status' do
          subject { put :update, id: work_order.id, company_id: nil, customer_id: nil, status: 'invalid_status' }

          it 'assigns the work_order as @work_order' do
            subject
            expect(assigns(:work_order)).to eq(work_order)
          end

          it 'returns a 204 status code' do
            subject
            expect(response).to have_http_status(422)
          end

          it 'response body to contain errors' do
            subject
            expected = {
                errors: {
                    status: ["is invalid", "is not included in the list"]
                }
            }.to_json
            expect(response.body).to eq(expected)
          end
        end
      end
    end
  end
end
