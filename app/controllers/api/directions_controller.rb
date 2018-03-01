module Api
  class DirectionsController < Api::ApplicationController
    def index
      raise BadRequest unless from_coordinate && to_coordinate
      render status: :ok, json: fetch_driving_directions
    end

    def eta
      raise BadRequest unless from_coordinate && to_coordinate
      eta = RoutingService.driving_eta(waypoint_coordinates)
      render status: :ok, json: { minutes: eta }
    end

    def places
      raise BadRequest unless params[:q] && coordinate
      @contacts = RoutingService.autocomplete_places(params[:q], coordinate, radius, params[:type], params[:components])
      respond_with(:api, @contacts, template: 'api/contacts/index', status: :ok)
    end

    private

    def fetch_driving_directions
      RoutingService.driving_directions(waypoint_coordinates)
    end

    def coordinate
      @coordinate ||= begin
        params[:latitude] && params[:longitude] ? Coordinate.new(params[:latitude], params[:longitude]) : nil
      end
    end

    def from_coordinate
      @from_coordinate ||= begin
        params[:from_latitude] && params[:from_longitude] ? Coordinate.new(params[:from_latitude], params[:from_longitude]) : nil
      end
    end

    def to_coordinate
      @to_coordinate ||= begin
        params[:to_latitude] && params[:to_longitude] ? Coordinate.new(params[:to_latitude], params[:to_longitude]) : nil
      end
    end

    def radius
      return 50 unless params[:radius]
      params[:radius].to_i rescue 50
    end

    def waypoint_coordinates
      @waypoint_coordinates ||= begin
        waypoint_coordinates = [from_coordinate]
        waypoints = JSON.parse(URI.decode(params[:waypoints])) rescue nil
        waypoints ||= []
        last_coordinate = nil
        waypoints.each do |waypoint|
          coordinate = Coordinate.new(waypoint[0], waypoint[1]) if waypoint.size == 2
          waypoint_coordinates << coordinate if coordinate != last_coordinate
          last_coordinate == coordinate
        end
        waypoint_coordinates << to_coordinate
        waypoint_coordinates
      end
    end
  end
end
