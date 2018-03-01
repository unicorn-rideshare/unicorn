require 'rails_helper'

describe 'api/routes/show' do
  let(:start_at)  { DateTime.parse('2015-02-08T19:00:00Z') }
  let(:end_at)    { DateTime.parse('2015-02-09T04:00:00Z') }
  let(:route)     { FactoryGirl.create(:route,
                                       :with_dispatcher_origin_assignment,
                                       :with_provider_origin_assignment,
                                       name: 'early bird',
                                       identifier: 'abc123',
                                       date: start_at.to_date,
                                       scheduled_start_at: start_at,
                                       scheduled_end_at: end_at,
                                       fastest_here_api_route_id: 'fast-route-id',
                                       shortest_here_api_route_id: 'short-route-id') }

  it 'should render route' do
    @route = route
    render
    expect(JSON.parse(rendered)).to eq(
                                        'id' => route.id,
                                        'dispatcher_origin_assignment_id' => route.dispatcher_origin_assignment_id,
                                        'provider_origin_assignment_id' => route.provider_origin_assignment_id,
                                        'name' => 'early bird',
                                        'identifier' => 'abc123',
                                        'fastest_here_api_route_id' => 'fast-route-id',
                                        'shortest_here_api_route_id' => 'short-route-id',
                                        'date' => '2015-02-08',
                                        'scheduled_start_at' => '2015-02-08T19:00:00Z',
                                        'scheduled_end_at' => '2015-02-09T04:00:00Z',
                                        'started_at' => nil,
                                        'ended_at' => nil,
                                        'loading_started_at' => nil,
                                        'loading_ended_at' => nil,
                                        'unloading_started_at' => nil,
                                        'unloading_ended_at' => nil,
                                        'items_loaded' => [],
                                        'incomplete_manifest' => false,
                                        'status' => 'awaiting_schedule'
                                    )
  end

  context 'when @include_legs is true' do
    it 'should render the legs with the route' do
      @route = route
      @include_legs = true
      render
      expect(JSON.parse(rendered)).to eq(
                                          'id' => route.id,
                                          'dispatcher_origin_assignment_id' => route.dispatcher_origin_assignment_id,
                                          'provider_origin_assignment_id' => route.provider_origin_assignment_id,
                                          'name' => 'early bird',
                                          'identifier' => 'abc123',
                                          'fastest_here_api_route_id' => 'fast-route-id',
                                          'shortest_here_api_route_id' => 'short-route-id',
                                          'date' => '2015-02-08',
                                          'scheduled_start_at' => '2015-02-08T19:00:00Z',
                                          'scheduled_end_at' => '2015-02-09T04:00:00Z',
                                          'started_at' => nil,
                                          'ended_at' => nil,
                                          'loading_started_at' => nil,
                                          'loading_ended_at' => nil,
                                          'unloading_started_at' => nil,
                                          'unloading_ended_at' => nil,
                                          'legs' => [],
                                          'items_loaded' => [],
                                          'incomplete_manifest' => false,
                                          'status' => 'awaiting_schedule'
                                      )
    end
  end

  context 'when @include_dispatcher_origin_assignment is true' do
    it 'should render the dispatcher origin assignment with the route' do
      @route = route
      @include_dispatcher_origin_assignment = true
      render
      expect(JSON.parse(rendered)).to eq(
                                          'id' => route.id,
                                          'dispatcher_origin_assignment_id' => route.dispatcher_origin_assignment_id,
                                          'provider_origin_assignment_id' => route.provider_origin_assignment_id,
                                          'name' => 'early bird',
                                          'identifier' => 'abc123',
                                          'fastest_here_api_route_id' => 'fast-route-id',
                                          'shortest_here_api_route_id' => 'short-route-id',
                                          'date' => '2015-02-08',
                                          'scheduled_start_at' => '2015-02-08T19:00:00Z',
                                          'scheduled_end_at' => '2015-02-09T04:00:00Z',
                                          'started_at' => nil,
                                          'ended_at' => nil,
                                          'loading_started_at' => nil,
                                          'loading_ended_at' => nil,
                                          'unloading_started_at' => nil,
                                          'unloading_ended_at' => nil,
                                          'items_loaded' => [],
                                          'incomplete_manifest' => false,
                                          'status' => 'awaiting_schedule',
                                          'dispatcher_origin_assignment' => Rabl::Renderer.new('dispatcher_origin_assignments/show',
                                                                                               route.dispatcher_origin_assignment,
                                                                                               view_path: 'app/views',
                                                                                               format: 'hash').render.with_indifferent_access
                                      )
    end
  end

  context 'when @include_provider_origin_assignment is true' do
    it 'should render the provider origin assignment with the route' do
      @route = route
      @include_provider_origin_assignment = true
      render
      expect(JSON.parse(rendered)).to eq(
                                          'id' => route.id,
                                          'dispatcher_origin_assignment_id' => route.dispatcher_origin_assignment_id,
                                          'provider_origin_assignment_id' => route.provider_origin_assignment_id,
                                          'name' => 'early bird',
                                          'identifier' => 'abc123',
                                          'fastest_here_api_route_id' => 'fast-route-id',
                                          'shortest_here_api_route_id' => 'short-route-id',
                                          'date' => '2015-02-08',
                                          'scheduled_start_at' => '2015-02-08T19:00:00Z',
                                          'scheduled_end_at' => '2015-02-09T04:00:00Z',
                                          'started_at' => nil,
                                          'ended_at' => nil,
                                          'loading_started_at' => nil,
                                          'loading_ended_at' => nil,
                                          'unloading_started_at' => nil,
                                          'unloading_ended_at' => nil,
                                          'items_loaded' => [],
                                          'incomplete_manifest' => false,
                                          'status' => 'awaiting_schedule',
                                          'provider_origin_assignment' => Rabl::Renderer.new('provider_origin_assignments/show',
                                                                                             route.provider_origin_assignment,
                                                                                             view_path: 'app/views',
                                                                                             format: 'hash').render.with_indifferent_access,
                                      )
    end
  end

  context 'when @include_work_orders is true' do
    it 'should render the work orders with the route' do
      @route = route
      @include_work_orders = true
      render
      expect(JSON.parse(rendered)).to eq(
                                          'id' => route.id,
                                          'dispatcher_origin_assignment_id' => route.dispatcher_origin_assignment_id,
                                          'provider_origin_assignment_id' => route.provider_origin_assignment_id,
                                          'name' => 'early bird',
                                          'identifier' => 'abc123',
                                          'fastest_here_api_route_id' => 'fast-route-id',
                                          'shortest_here_api_route_id' => 'short-route-id',
                                          'date' => '2015-02-08',
                                          'scheduled_start_at' => '2015-02-08T19:00:00Z',
                                          'scheduled_end_at' => '2015-02-09T04:00:00Z',
                                          'started_at' => nil,
                                          'ended_at' => nil,
                                          'loading_started_at' => nil,
                                          'loading_ended_at' => nil,
                                          'unloading_started_at' => nil,
                                          'unloading_ended_at' => nil,
                                          'work_orders' => [],
                                          'items_loaded' => [],
                                          'incomplete_manifest' => false,
                                          'status' => 'awaiting_schedule'
                                      )
    end
  end

  context 'when the route manifest has items loaded' do
    let(:route)   { FactoryGirl.create(:route,
                                       :with_dispatcher_origin_assignment,
                                       :with_provider_origin_assignment,
                                       :with_work_orders_and_items_ordered) }
    before do
      route.items_loaded << route.items_ordered.first
    end

    it 'should render the items currently loaded on the truck' do
      @route = route
      render
      expect(JSON.parse(rendered)['items_loaded'].size).to eq(1)
    end
  end
end
