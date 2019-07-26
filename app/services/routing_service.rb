class RoutingService
  class << self
    ROUTE_LEG_DELAY = 15.minutes
    ORIGIN_LOAD_DELAY = 30.minutes
    START_TIME_OFFSET = 30.minutes

    def tourguide
      Provide::Services::Tourguide.new((ENV['TOURGUIDE_API_SCHEME'] || 'http'), ENV['TOURGUIDE_API_HOST'], ENV['PROVIDE_APPLICATION_API_TOKEN'])
    end

    def autocomplete_places(query, coordinate, radius = 50, type = nil, components = nil)
      results = []
      _, response = tourguide.places_autocomplete(query, coordinate.latitude, coordinate.longitude, radius, type, components)
      response.each do |result|
        results << Contact.new(description: result['description'],
                               city: result['city'],
                               state: result['state'],
                               data: result['data'])
      end
      results
    end

    def driving_directions(waypoint_coordinates)
      origin = waypoint_coordinates.first
      destination = waypoint_coordinates.last

      _, response = tourguide.directions(origin.latitude, origin.longitude, destination.latitude, destination.longitude)
      response
    end

    def driving_estimates(waypoint_coordinates, mode = 'fastest;truck')
      origin = waypoint_coordinates.first
      destination = waypoint_coordinates.last

      _, response = tourguide.eta(origin.latitude, origin.longitude, destination.latitude, destination.longitude)
      response
    end

    def driving_eta(waypoint_coordinates)
      driving_estimates(waypoint_coordinates)['minutes'] rescue nil
    end

    def place_details(place_id)
      _, result = tourguide.place_details(place_id)
      result
    end

    def timezone(coordinate, timestamp = nil)
      _, result = tourguide.timezones(coordinate.latitude, coordinate.longitude)
      TimeZone.find(result['time_zone_id']) rescue nil
    end

    def generate_route(route, work_orders, departure_at = DateTime.now + START_TIME_OFFSET, params = { })
      origin = route.provider_origin_assignment.origin
      origin_load_delay = params[:origin_load_delay] || ORIGIN_LOAD_DELAY

      work_orders = work_orders.ordered_by_distance_from_coordinate(origin.contact.coordinate)
      routed_work_orders = []

      start_coord = origin.contact.coordinate
      dest_coords = work_orders.collect { |wo| wo.customer.contact.coordinate }

      if start_coord && dest_coords.size > 0
        calculated_routes, matrix = Unicorn::Routing::MatrixCalculator.calculate(start_coord, dest_coords, params)

        calculated_routes.each do |route_coords|
          time_spent = 0.minutes
          start_time = (departure_at || route.scheduled_start_at || Date.today.to_datetime.beginning_of_day + (params[:start_time_offset] || START_TIME_OFFSET).seconds) + origin_load_delay

          route_coords.each_with_index do |route_coord, i|
            destination_index = route_coord[1]

            estimated_start_at = nil
            estimated_end_at = nil

            if i > 0
              if time_spent == 0
                estimated_start_at = start_time - matrix[i - 1][destination_index][:time].seconds
                estimated_end_at = start_time

                time_spent += ROUTE_LEG_DELAY
              else
                previous_destination_index = route_coords[i - 1][1]

                estimated_start_at = start_time + time_spent
                estimated_end_at = estimated_start_at + matrix[previous_destination_index][destination_index][:time].seconds

                time_spent += matrix[previous_destination_index][destination_index][:time].seconds + ROUTE_LEG_DELAY
              end

              work_order = work_orders[destination_index - 1]
              work_order.scheduled_start_at = estimated_end_at
              work_order.estimated_duration = estimated_end_at - estimated_start_at
              work_order.schedule!

              if route.awaiting_schedule?
                route.legs.build(
                    estimated_start_at: estimated_start_at,
                    estimated_end_at: estimated_end_at,
                    estimated_traffic: 1,
                    work_order: work_order
                ) unless work_order.route_leg_id
              end

              routed_work_orders << work_order
            end
          end

          unless route.awaiting_schedule?
            route.transaction do
              route.legs.each_with_index do |leg, i|
                work_order = routed_work_orders[i]
                work_order.route_leg_id = leg.id
                work_order.reschedule!
              end
            end
          end

          coordinates = waypoint_coordinates(route)
          route.fastest_here_api_route_id = calculate_fastest_here_api_route_id(coordinates)
          route.shortest_here_api_route_id = calculate_shortest_here_api_route_id(coordinates)

          route.scheduled_start_at = route.legs.first.estimated_start_at - origin_load_delay unless route.scheduled_start_at
          route.schedule!
        end
      end
    end

    def calculate_matrix(start_coords = [], destination_coords = [])

      matrix = nil
      remaining_attempts = 10

      while matrix.nil? && remaining_attempts > 0
        remaining_attempts -= 1
        code, response = tourguide.matrix(start_coords, destination_coords)
        if code == 200
          matrix = response
        else
          # TODO-- log this more formally
          puts "WARNING: response from HERE API was #{response.code}"
          puts 'Sleeping 5 seconds...'
          sleep 5.0
        end
      end

      matrix
    end

    private

    def calculate_fastest_here_api_route_id(coordinates, transport='truck', traffic='enabled')
      directions_api_params = RoutingService.default_directions_api_params
      directions_api_params[:mode] = "fastest;#{transport};traffic:#{traffic}"
      directions_api_params[:representation] = 'overview'
      directions = RoutingService.driving_directions(coordinates, directions_api_params.with_indifferent_access)
      route = directions['route'].first if directions && directions['route'] && directions['route'].size > 0
      route['routeId'] if route
    end

    def calculate_shortest_here_api_route_id(coordinates, transport='car', traffic='enabled') # api now only supports 'car' with 'shortest'
      directions_api_params = RoutingService.default_directions_api_params
      directions_api_params[:mode] = "shortest;#{transport};traffic:#{traffic}"
      directions_api_params[:representation] = 'overview'
      directions = RoutingService.driving_directions(coordinates, directions_api_params.with_indifferent_access)
      route = directions['route'].first if directions && directions['route'] && directions['route'].size > 0
      route['routeId'] if route
    end

    def waypoint_coordinates(route)
      origin_coord = route.provider_origin_assignment.origin.contact.coordinate
      coordinates = []
      coordinates << origin_coord if origin_coord
      route.work_orders.each do |work_order|
        coordinates << work_order.customer.contact.coordinate
      end
      coordinates << origin_coord if origin_coord
      coordinates
    end
  end
end
