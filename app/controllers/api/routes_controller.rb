module Api
  class RoutesController < Api::ApplicationController
    load_and_authorize_resource only: [:index, :show, :create, :update, :destroy]

    before_action :filter_by_user, only: [:index], unless: lambda { params[:filter_by_user].nil? }
    before_action :infer_scheduled_start_at, only: [:update], unless: lambda { !infer_scheduled_start_at? }
    before_action :handle_status_transition, only: [:create, :update], unless: lambda { params[:status].nil? }
    before_action :reroute_work_orders, only: [:update], unless: lambda { params[:work_order_ids].nil? }
    before_action :route_work_orders, only: [:create], unless: lambda { params[:work_order_ids].nil? }
    before_action :update_manifest, only: [:update], unless: lambda { !params.has_key?(:gtins_loaded) }

    def index
      @api = true
      @routes = @routes.ordered_by_started_at_desc if params[:sort_started_at_desc].to_s.match(/^true$/i)
      @routes = filter_by(@routes.greedy, indexes)
      @include_legs = params[:include_legs].to_s.match(/^true$/i)
      @include_products = params[:include_products].to_s.match(/^true$/i)
      @include_dispatcher_origin_assignment = params[:include_dispatcher_origin_assignment].to_s.match(/^true$/i)
      @include_provider_origin_assignment = params[:include_provider_origin_assignment].to_s.match(/^true$/i)
      @include_work_orders = params[:include_work_orders].to_s.match(/^true$/i)
      @include_work_order_providers = params[:include_work_order_providers] ? params[:include_work_order_providers].to_s.match(/^true$/i) : @include_work_orders
      @include_checkin_coordinates = params[:include_checkin_coordinates].to_s.match(/^true$/i)
      respond_with(:api, @routes)
    end

    def show
      @api = true
      @include_legs = params[:include_legs].to_s.match(/^true$/i)
      @include_products = params[:include_products].to_s.match(/^true$/i)
      @include_dispatcher_origin_assignment = params[:include_dispatcher_origin_assignment].to_s.match(/^true$/i)
      @include_provider_origin_assignment = params[:include_provider_origin_assignment].to_s.match(/^true$/i)
      @include_work_orders = params[:include_work_orders].to_s.match(/^true$/i)
      @include_work_order_providers = params[:include_work_order_providers] ? params[:include_work_order_providers].to_s.match(/^true$/i) : @include_work_orders
      @include_checkin_coordinates = params[:include_checkin_coordinates].to_s.match(/^true$/i)
      respond_with(:api, @route)
    end

    def create
      @route.save && true
      respond_with(:api, @route, template: 'api/routes/show', status: :created)
    end

    def update
      @route.update(route_params)
      respond_with(:api, @route)
    end

    def destroy
      @route.destroy
      respond_with(:api, @route)
    end

    private

    def indexes
      [:company_id, :provider_origin_assignment_id, :dispatcher_origin_assignment_id, :date, :scheduled_start_at, :started_at, :identifier]
    end

    def route_params
      params.permit(
          :company_id, :name, :identifier, :date, :dispatcher_origin_assignment_id, :provider_origin_assignment_id, :status
      )
    end

    def filter_by_user
      key = :dispatcher_origin_assignment_ids || :provider_origin_assignment_ids
      assignables = key == :dispatcher_origin_assignment_ids ? current_user.dispatchers : current_user.providers
      params[key] = assignables.map { |assignable| assignable.origin_assignments.unscoped.map(&:id) }.flatten
    end

    def recalculate_route
      RoutingService.generate_route(@route, @route.work_orders)
    end

    def reroute_work_orders
      work_order_ids = params.delete(:work_order_ids)
      return if @route.work_order_ids.map(&:to_s) == work_order_ids.map(&:to_s)

      eligible_route_legs = @route.legs.select { |leg| leg.can_schedule? || leg.can_start? }
      eligible_work_orders = eligible_route_legs.map(&:work_order)
      eligible_work_order_ids = eligible_work_orders.map(&:id)

      raise UnprocessableEntity if eligible_work_order_ids.sort.map(&:to_s) != work_order_ids.sort.map(&:to_s)

      work_orders = eligible_work_orders.sort_by { |wo| work_order_ids.map(&:to_s).find_index(wo.id.to_s) }
      scheduled_start_timestamps = work_orders.map(&:scheduled_start_at).sort
      scheduled_end_timestamps = work_orders.map(&:scheduled_end_at).sort
      legs = eligible_route_legs.sort_by { |leg| eligible_work_order_ids.map(&:to_s).find_index(leg.work_order.id.to_s)  }

      @route.transaction do
        legs.each_with_index do |leg, i|
          work_order = work_orders[i]
          work_order.scheduled_start_at = scheduled_start_timestamps[i]
          work_order.scheduled_end_at = scheduled_end_timestamps[i]
          work_order.route_leg_id = leg.id
          work_order.reschedule!
        end
      end
    end

    def route_work_orders
      work_order_ids = params.delete(:work_order_ids) || @route.work_order_ids
      work_orders = @route.provider_origin_assignment.provider.company.work_orders.where(id: work_order_ids)

      departure_offset = 0
      @route.provider_origin_assignment.routes.map { |route| departure_offset += route.duration.to_i }
      departure_at = DateTime.parse(params[:departure_at]) if params[:departure_at] rescue nil
      departure_at ||= DateTime.now
      RoutingService.generate_route(@route, work_orders, departure_at + departure_offset.to_i.seconds)
    end

    def infer_scheduled_start_at?
      @route.status.to_sym == :awaiting_schedule && params[:status].to_s.to_sym == :scheduled
    end

    def infer_scheduled_start_at
      scheduled_start_at = params[:scheduled_start_at] ? DateTime.parse(params[:scheduled_start_at]) : DateTime.now
      @route.scheduled_start_at = scheduled_start_at || @route.legs.first.work_order.scheduled_start_at
      route_work_orders
    end

    def update_manifest # FIXME-- determine how to clean up the business logic contained herein
      params[:gtins_loaded] ||= []
      gtins_loaded = params.delete(:gtins_loaded)

      raise BadRequest unless gtins_loaded && gtins_loaded.respond_to?(:size)

      products = gtins_loaded.map { |gtin| @route.provider_origin_assignment.provider.company.products.where(gtin: gtin).first }
      raise BadRequest unless products

      @route.transaction do # @route.items_loaded = products did not work by itself when attempting to add a duplicate item
        @route.items_loaded = []
        @route.items_loaded = products
      end
    end
  end
end
