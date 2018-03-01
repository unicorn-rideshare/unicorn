require 'rails_helper'

describe Api::RoutesController, api: true do
  let(:user)                          { FactoryGirl.create(:user) }
  let(:company)                       { FactoryGirl.create(:company, user: user) }
  let(:dispatcher_user)               { FactoryGirl.create(:user) }
  let(:dispatcher)                    { FactoryGirl.create(:dispatcher, company: company, user: dispatcher_user) }
  let(:provider_user)                 { FactoryGirl.create(:user) }
  let(:provider)                      { FactoryGirl.create(:provider, company: company, user: provider_user) }
  let(:market)                        { FactoryGirl.create(:market, company: company) }
  let(:origin)                        { FactoryGirl.create(:origin, market: market) }
  let(:dispatcher_origin_assignment)  { FactoryGirl.create(:dispatcher_origin_assignment, dispatcher: dispatcher, origin: origin, start_date: Date.today, end_date: Date.today) }
  let(:provider_origin_assignment)    { FactoryGirl.create(:provider_origin_assignment, provider: provider, origin: origin, start_date: Date.today, end_date: Date.today) }
  let(:route)                         { FactoryGirl.create(:route, dispatcher_origin_assignment: dispatcher_origin_assignment, provider_origin_assignment: provider_origin_assignment) }

  before do
    sign_in user
  end

  it_behaves_like 'api_controller', :index, :show, :update, :destroy do
    let(:resource) { route }
  end

  describe '#index' do
    before { route }

    context 'when the :include_legs param is true' do
      let(:params) { { include_legs: true } }

      subject { get :index, params }

      it 'returns a 200 status code' do
        subject
        expect(response).to have_http_status(200)
      end

      it 'should render the show template' do
        subject
        expect(response).to render_template('index')
      end

      it 'should return a list of route legs with each route in the response' do
        subject
        expect(JSON.parse(response.body).first['legs']).to_not be_nil
      end
    end

    context 'when the :include_work_orders param is true' do
      let(:params) { { include_work_orders: true } }

      subject { get :index, params }

      it 'returns a 200 status code' do
        subject
        expect(response).to have_http_status(200)
      end

      it 'should render the show template' do
        subject
        expect(response).to render_template('index')
      end

      it 'should return a list of work orders with each route in the response' do
        subject
        expect(JSON.parse(response.body).first['work_orders']).to_not be_nil
      end
    end
  end

  describe '#create' do
    let(:dispatcher_origin_assignment)  { FactoryGirl.create(:dispatcher_origin_assignment, dispatcher: dispatcher, origin: origin, start_date: Date.today, end_date: Date.today + 1.day) }
    let(:provider_origin_assignment)    { FactoryGirl.create(:provider_origin_assignment, provider: provider, origin: origin, start_date: Date.today, end_date: Date.today) }

    context 'with valid params' do
      let(:params) { { company_id: company.id,
                       date: dispatcher_origin_assignment.start_date.to_s,
                       dispatcher_origin_assignment_id: dispatcher_origin_assignment.id,
                       provider_origin_assignment_id: provider_origin_assignment.id } }

      subject { post :create, params }

      it 'creates a new Route' do
        expect { subject }.to change(Route, :count).by(1)
      end

      it 'assigns a newly created route as @route' do
        subject
        expect(assigns(:route)).to be_a(Route)
        expect(assigns(:route)).to be_persisted
      end

      it 'assigns the newly created route provider_origin_assignment' do
        subject
        expect(assigns(:route).provider_origin_assignment).to eq(provider_origin_assignment)
      end

      it 'returns a 201 status code' do
        subject
        expect(response).to have_http_status(201)
      end

      it 'should render the show template' do
        subject
        expect(response).to render_template('show')
      end

      context 'when the params contain :work_order_ids', vcr: { cassette_name: 'tourguide_api_calculate_matrix_for_routes_api_1' } do
        let(:work_order1) { FactoryGirl.create(:work_order, company: company) }
        let(:work_order2) { FactoryGirl.create(:work_order, company: company) }
        let(:params)      { { company_id: company.id,
                              date: dispatcher_origin_assignment.start_date.to_s,
                              dispatcher_origin_assignment_id: dispatcher_origin_assignment.id,
                              provider_origin_assignment_id: provider_origin_assignment.id,
                              work_order_ids: [work_order2.id, work_order1.id] } }
        let(:contact)     { provider_origin_assignment.origin.contact }
        let(:latitude)    { BigDecimal('33.9253024') }
        let(:longitude)   { BigDecimal('-84.3857442') }

        before do
          contact.latitude = latitude
          contact.longitude = longitude
          contact.skip_geocode = true
          contact.save

          customer_coords = [
              Coordinate.new(33.848770, -84.373336),
              Coordinate.new(33.845153, -84.370063)
          ]

          [work_order1, work_order2].each do |wo|
            coord = customer_coords.shift

            customer = wo.customer
            contact = customer.contact
            contact.skip_geocode = true
            contact.latitude = coord.latitude
            contact.longitude = coord.longitude
            contact.save
          end
        end

        subject { post :create, params }

        context 'when the specified work orders each have a :preferred_scheduled_start_date equal to the given :date' do
          before do
            [work_order1, work_order2].each do |wo|
              wo.preferred_scheduled_start_date = dispatcher_origin_assignment.start_date.to_s
              wo.save
            end
          end

          xit 'creates a new Route' do
            expect { subject }.to change(Route, :count).by(1)
          end

          xit 'assigns a newly created route as @route' do
            subject
            expect(assigns(:route)).to be_a(Route)
            expect(assigns(:route)).to be_persisted
          end

          xit 'returns a 201 status code' do
            subject
            expect(response).to have_http_status(201)
          end

          xit 'should render the show template' do
            subject
            expect(response).to render_template('show')
          end

          xit 'should setup the route legs on the new route' do
            subject
            expect(assigns(:route).reload.legs.count).to eq(2)
          end

          xit 'should schedule the new route' do
            subject
            expect(assigns(:route).reload.status).to eq('scheduled')
          end

          xit 'should schedule and expose the work orders on the new route' do
            subject
            expect(work_order1.reload.status).to eq('scheduled')
            expect(work_order2.reload.status).to eq('scheduled')
            expect(assigns(:route).reload.work_orders).to eq([work_order2, work_order1])
          end
        end
      end
    end

    describe 'with invalid params' do
      context 'with invalid dispatcher_origin_assignment id' do
        subject { post :create, dispatcher_origin_assignment: nil }

        it 'should restrict access' do
          expect(subject).to have_http_status(:forbidden)
        end
      end

      context 'with invalid provider_origin_assignment id' do
        subject { post :create, provider_origin_assignment: nil }

        it 'should restrict access' do
          expect(subject).to have_http_status(:forbidden)
        end
      end
    end
  end

  describe '#update' do
    describe 'with valid params' do
      let(:params) { { } }
      subject { put :update, params.merge(id: route.id) }

      it 'updates the requested route' do
        expect_any_instance_of(Route).to receive(:update)
        subject
      end

      it 'assigns the requested route as @route' do
        subject
        expect(assigns(:route)).to eq(route)
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
        before { sign_in FactoryGirl.create(:user) }

        it 'should restrict access' do
          expect(subject).to have_http_status(:forbidden)
        end
      end

      context 'when the request contains a :status' do
        context 'when the :status is scheduled' do
          let(:route) { FactoryGirl.create(:route,
                                           :with_work_orders_and_items_ordered,
                                           provider_origin_assignment: provider_origin_assignment) }

          subject     { put :update, params.merge(id: route.id) }

          before do
            allow(RoutingService).to receive(:generate_route) { }

            wo = route.work_orders.first
            wo.scheduled_start_at = DateTime.now + 10.minutes
            wo.schedule!

            params.merge!(status: 'scheduled')
          end

          context 'when no :scheduled_start_at parameter is provided' do
            it 'should transition the route to scheduled' do
              subject
              expect(route.reload.status).to eq('scheduled')
            end

            it 'should set the :scheduled_start_at value on the route' do
              subject
              expect(route.reload.scheduled_start_at).not_to be_nil
            end
          end

          context 'when a :scheduled_start_at parameter is provided' do
            context 'when the :scheduled_start_at parameter is nil' do
              subject { put :update, params.merge(id: route.id, start_at: nil) }

              it 'should transition the route to scheduled' do
                subject
                expect(route.reload.status).to eq('scheduled')
              end

              it 'should set the :scheduled_start_at value on the route' do
                subject
                expect(route.reload.scheduled_start_at).not_to be_nil
              end
            end

            context 'when the :scheduled_start_at parameter is a valid timestamp' do
              let(:start_at) { DateTime.now }

              subject { put :update, params.merge(id: route.id, status: 'scheduled', scheduled_start_at: start_at.to_s) }

              it 'should transition the route to scheduled' do
                subject
                expect(route.reload.status).to eq('scheduled')
              end

              it 'should set the :scheduled_start_at value on the route using the given :scheduled_start_at parameter' do
                subject
                expect(route.reload.scheduled_start_at.to_datetime.to_s).to eq(start_at.to_datetime.utc.to_s)
              end
            end
          end
        end

        context 'when the :status is loading' do
          context 'when the current status is :scheduled' do
            let(:route) { FactoryGirl.create(:route,
                                             :scheduled,
                                             :with_work_orders_and_items_ordered,
                                             provider_origin_assignment: provider_origin_assignment) }

            subject     { put :update, params.merge(id: route.id) }

            before do
              params.merge!(status: 'loading')
            end

            it 'should transition the route to loading' do
              subject
              expect(route.reload.status).to eq('loading')
            end
          end

          context 'when the current status is :loading' do
            let(:route) { FactoryGirl.create(:route,
                                             :loading,
                                             :with_work_orders_and_items_ordered,
                                             provider_origin_assignment: provider_origin_assignment) }

            subject     { put :update, params.merge(id: route.id) }

            before do
              params.merge!(status: 'loading')
            end

            it 'should be a no-op' do
              expect(subject).to have_http_status(:no_content)
            end
          end
        end

        context 'when the :status is in_progress' do
          let(:route) { FactoryGirl.create(:route,
                                           :loading,
                                           :with_work_orders_and_items_ordered,
                                           provider_origin_assignment: provider_origin_assignment) }

          subject     { put :update, params.merge(id: route.id) }

          before do
            params.merge!(status: 'in_progress')
          end

          context 'when the manifest for the route is incomplete' do
            it 'should not transition the route to in_progress' do
              subject
              expect(route.reload.status).to eq('loading')
            end
          end

          context 'when the manifest for the route is complete' do
            before do
              route.work_orders.each do |wo|
                wo.items_ordered.shuffle.each do |product|
                  route.items_loaded << product
                end
              end
            end

            it 'should transition the route to in_progress' do
              subject
              expect(route.reload.status).to eq('in_progress')
            end
          end
        end

        context 'when the :status is unloading' do
          let(:route) { FactoryGirl.create(:route,
                                           :in_progress,
                                           :with_work_orders_and_items_ordered,
                                           provider_origin_assignment: provider_origin_assignment) }

          subject     { put :update, params.merge(id: route.id) }

          before do
            params.merge!(status: 'unloading')
          end

          it 'should transition the route to unloading' do
            subject
            expect(route.reload.status).to eq('unloading')
          end
        end

        context 'when the :status is completed' do
          let(:route) { FactoryGirl.create(:route,
                                           :in_progress,
                                           :with_work_orders_and_items_ordered,
                                           provider_origin_assignment: provider_origin_assignment) }

          subject     { put :update, params.merge(id: route.id, status: 'completed') }

          it 'should transition the route to completed' do
            subject
            expect(route.reload.status).to eq('completed')
          end
        end
      end

      context 'when the request contains :leg_ids' do
        let(:route) { FactoryGirl.create(:route,
                                         :scheduled,
                                         :with_work_orders_and_items_ordered,
                                         provider_origin_assignment: provider_origin_assignment) }

        let(:leg0)    { route.legs[0] }
        let(:leg1)    { route.legs[1] }
        let(:leg2)    { route.legs[2] }
        let(:leg3)    { route.legs.create(work_order: FactoryGirl.create(:work_order, company: route.provider_origin_assignment.provider.company)) }

        let(:wo0)     { leg0.work_order }
        let(:wo1)     { leg1.work_order }
        let(:wo2)     { leg2.work_order }
        let(:wo3)     { leg3.work_order }

        before do
          expect(route.reload.legs).to eq([leg0, leg1, leg2, leg3])

          wo0.scheduled_start_at = DateTime.now + 5.minutes
          wo0.schedule! && wo0.start! && wo0.complete!

          wo1.scheduled_start_at = DateTime.now + 1.hour
          wo1.schedule!

          wo2.scheduled_start_at = DateTime.now + 2.hours
          wo2.schedule!

          wo3.scheduled_start_at = DateTime.now + 3.hours
          wo3.schedule!
        end

        context 'when the given route work order ids contain an id that does not belong to the route' do
          subject { put :update, params.merge(id: route.id, work_order_ids: [FactoryGirl.create(:work_order).id, wo1.id, wo3.id]) }

          it 'assigns the requested route as @route' do
            subject
            expect(assigns(:route)).to eq(route)
          end

          it 'returns a 422 status code' do
            subject
            expect(response).to have_http_status(422)
          end
        end

        context 'when the given route work order ids are valid for the route being updated' do
          before { route.legs.create() }

          context 'when the given work order ids attempt to move an in-progress work order' do
            before { wo1.route! }

            subject { put :update, params.merge(id: route.id, work_order_ids: [wo2.id, wo1.id, wo3.id]) }

            it 'assigns the requested route as @route' do
              subject
              expect(assigns(:route)).to eq(route)
            end

            it 'returns a 422 status code' do
              subject
              expect(response).to have_http_status(422)
            end

            it 'reorders the route work orders as specified by the order of the given :work_order_ids' do
              subject
              work_orders = assigns(:route).reload.work_orders
              expect(work_orders[0]).to eq(wo0)
              expect(work_orders[1]).to eq(wo1)
              expect(work_orders[2]).to eq(wo2)
              expect(work_orders[3]).to eq(wo3)
            end
          end

          context 'when the given work order ids attempt to move a scheduled work order later in the route' do
            subject { put :update, params.merge(id: route.id, work_order_ids: [wo1.id, wo3.id, wo2.id]) }

            it 'assigns the requested route as @route' do
              subject
              expect(assigns(:route)).to eq(route)
            end

            it 'returns a 204 status code' do
              subject
              expect(response).to have_http_status(204)
            end

            it 'reorders the route work orders as specified by the order of the given :work_order_ids' do
              subject
              work_orders = assigns(:route).reload.work_orders
              expect(work_orders[0]).to eq(wo0)
              expect(work_orders[1]).to eq(wo1)
              expect(work_orders[2]).to eq(wo3)
              expect(work_orders[3]).to eq(wo2)
            end
          end

          context 'when the given work order ids attempt to move an abandoned work order back into the schedule' do
            let(:wo4) { FactoryGirl.create(:work_order, :abandoned, company: wo1.company) }
            before { route.legs.create(work_order: wo4) }

            subject { put :update, params.merge(id: route.id, work_order_ids: [wo1.id, wo4.id, wo2.id, wo3.id]) }

            it 'assigns the requested route as @route' do
              subject
              expect(assigns(:route)).to eq(route)
            end

            it 'returns a 204 status code' do
              subject
              expect(response).to have_http_status(204)
            end

            it 'reorders the route work orders as specified by the order of the given :work_order_ids' do
              subject
              work_orders = assigns(:route).reload.work_orders
              expect(work_orders[0]).to eq(wo0)
              expect(work_orders[1]).to eq(wo1)
              expect(work_orders[2]).to eq(wo4)
              expect(work_orders[3]).to eq(wo2)
              expect(work_orders[4]).to eq(wo3)
            end
          end
        end
      end

      context 'when the request contains :gtins_loaded' do
        let(:route) { FactoryGirl.create(:route,
                                         :scheduled,
                                         :with_work_orders_and_items_ordered,
                                         provider_origin_assignment: provider_origin_assignment) }

        subject     { put :update, params.merge(id: route.id) }

        context 'when the manifest for the route is incomplete' do
          context 'when the :gtins_loaded param contains more than one gtin' do # this business rule may be temporary and is here currently to ensure only a single gtin is scanned and added at a time
            before do
              params.merge!(gtins_loaded: [route.items_ordered.first.gtin, route.items_ordered.second.gtin])
            end

            it 'assigns the requested route as @route' do
              subject
              expect(assigns(:route)).to eq(route)
            end

            it 'returns a `204` status code' do
              subject
              expect(response).to have_http_status(204)
            end

            it 'response body is empty' do
              subject
              expect(response.body).to eq('')
            end

            it 'should not add products for the given gtins to the route manifest (:items_loaded on the route)' do
              subject
              expect(route.reload.items_loaded).to eq([route.items_ordered.first, route.items_ordered.second])
            end
          end

          context 'when the :gtins_loaded param contains only gtins for items still needed on the manifest' do
            before do
              params.merge!(gtins_loaded: [route.items_ordered.first.gtin])
            end

            it 'assigns the requested route as @route' do
              subject
              expect(assigns(:route)).to eq(route)
            end

            it 'returns a 204 status code' do
              subject
              expect(response).to have_http_status(204)
            end

            it 'response body is empty' do
              subject
              expect(response.body).to eq('')
            end

            it 'should add products for the given gtins to the route manifest (:items_loaded on the route)' do
              subject
              expect(route.reload.items_loaded).to eq([route.items_ordered.first])
            end
          end
        end

        context 'when the manifest for the route is complete' do
          before do
            route.work_orders.each do |wo|
              wo.items_ordered.shuffle.each do |product|
                route.items_loaded << product
              end
            end
          end

          context 'when :gtins_loaded indicates that items have been removed from the route manifest' do
            let(:gtins_loaded) { route.items_ordered[0..route.items_ordered.size - 3].map(&:gtin) }
            before { params.merge!(gtins_loaded: gtins_loaded) }

            it 'assigns the requested route as @route' do
              subject
              expect(assigns(:route)).to eq(route)
            end

            it 'returns a 204 status code' do
              subject
              expect(response).to have_http_status(204)
            end

            it 'response body is empty' do
              subject
              expect(response.body).to eq('')
            end

            it 'removes as items corresponding to the gtins removed from the given :gtins_loaded param' do
              expect { subject }.to change(route.items_loaded, :count).by(-2)
            end

            it 'removes all of the items loaded which were not present in the given :gtins_loaded param' do
              subject
              expect(route.reload.items_loaded.map(&:gtin).sort).to eq(gtins_loaded.sort)
            end
          end

          context 'when :gtins_loaded is empty' do
            let(:gtins_loaded) { [] }
            before { params.merge!(gtins_loaded: gtins_loaded) }

            it 'assigns the requested route as @route' do
              subject
              expect(assigns(:route)).to eq(route)
            end

            it 'returns a 204 status code' do
              subject
              expect(response).to have_http_status(204)
            end

            it 'response body is empty' do
              subject
              expect(response.body).to eq('')
            end

            it 'removes as items corresponding to the gtins removed from the given :gtins_loaded param' do
              expect { subject }.to change(route.items_loaded, :count).by(-9)
            end

            it 'removes all of the items loaded which were not present in the given :gtins_loaded param' do
              subject
              expect(route.reload.items_loaded.map(&:gtin)).to eq(gtins_loaded)
            end
          end
        end
      end
    end

    describe 'with invalid params' do
      subject { put :update, id: route.id, status: 'invalid_status' }

      it 'assigns the route as @route' do
        subject
        expect(assigns(:route)).to eq(route)
      end

      it 'returns a 422 status code' do
        subject
        expect(response).to have_http_status(422)
      end

      it 'response body to contain errors' do
        subject
        expected = {
            errors: {
                status: ['is invalid', 'is not included in the list']
            }
        }.to_json
        expect(response.body).to eq(expected)
      end
    end

    context 'when the route is :pending_completion' do
      context 'when the user is a route dispatcher' do
        let(:route) { FactoryGirl.create(:route,
                                         :scheduled,
                                         :with_work_orders_and_items_ordered,
                                         dispatcher_origin_assignment: dispatcher_origin_assignment,
                                         provider_origin_assignment: provider_origin_assignment) }

        subject     { put :update, params.merge(id: route.id) }

        before { sign_in(dispatcher_origin_assignment.user) }
      end
    end
  end
end
