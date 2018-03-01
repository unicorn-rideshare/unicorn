module Api
  class RouteLegsController < Api::ApplicationController
    load_and_authorize_resource

    def index
      @route_legs = filter_by(@route_legs, indexes)
      respond_with(:api, @route_legs)
    end

    def update
      @route_leg.update(route_params)
      respond_with(:api, @route_leg)
    end

    private

    def indexes
      [:route_id]
    end

    def route_leg_params
      params.permit(
          :actual_start_at,
          :actual_end_at,
          :actual_traffic,
          :estimated_start_at,
          :estimated_end_at,
          :estimated_end_at_on_start,
          :estimated_traffic
      )
    end
  end
end
