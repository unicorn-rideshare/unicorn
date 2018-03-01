module Unicorn
  module Routing
    class MatrixCalculator
      DEFAULT_ROUTE_DISTANCE_MAX = 20000000.0
      DEFAULT_ROUTE_DURATION_MAX = 24.hours.seconds
      DEFAULT_SUB_MATRIX_WIDTH = 100
      DEFAULT_SUB_MATRIX_HEIGHT = 15
      UNLOAD_TIME = 20.minutes.seconds

      class << self
        def calculate(start_coord, destination_coords = [], params = { route_distance_max: DEFAULT_ROUTE_DISTANCE_MAX,
                                                                       route_duration_max: DEFAULT_ROUTE_DURATION_MAX,
                                                                       sub_matrix_width: SUB_MATRIX_WIDTH,
                                                                       sub_matrix_height: DEFAULT_SUB_MATRIX_HEIGHT })
          sub_matrix_width = params[:sub_matrix_width] || DEFAULT_SUB_MATRIX_WIDTH
          sub_matrix_height = params[:sub_matrix_height] || DEFAULT_SUB_MATRIX_HEIGHT

          destination_coords.unshift(start_coord)
          matrix = Unicorn::Routing::DistTimeMatrix.new(destination_coords.size)

          last_w_iteration = destination_coords.size % sub_matrix_width != 0 ? 1 : 0
          weight_iterations = destination_coords.size / sub_matrix_width + last_w_iteration

          last_h_iteration = destination_coords.size % sub_matrix_height != 0 ? 1 : 0
          height_iterations = destination_coords.size / sub_matrix_height + last_h_iteration

          current_height_border = 0
          current_width_border = 0

          for i in 0..height_iterations - 1 do
            for j in 0..weight_iterations - 1 do
              start_coords = destination_coords.slice(current_height_border..current_height_border + sub_matrix_height - 1)
              dest_coords = destination_coords.slice(current_width_border..current_width_border + sub_matrix_width - 1)
              sub_matrix = calc_sub_matrix(start_coords, dest_coords)
              matrix.buildup(current_height_border, current_width_border, sub_matrix)
              current_width_border += sub_matrix_width
            end
            current_width_border = 0
            current_height_border += sub_matrix_height
          end

          routes_array = calc_routes(matrix, destination_coords, params)
          return routes_array, matrix.values
        end

        private

        def calc_routes(matrix, destination_coords = [], params = {})
          routes_array = []

          coords_remaining = matrix.size - 1

          route_duration_max = params[:route_duration_max] || DEFAULT_ROUTE_DURATION_MAX # for now, force sane max duration until this is better understood
          enforce_route_duration_max = !route_duration_max.nil?

          route_distance_max = params[:route_distance_max] || DEFAULT_ROUTE_DISTANCE_MAX # for now, force sane max distance until this is better understood
          enforce_route_distance_max = !route_distance_max.nil?

          matrix.process

          while coords_remaining != 0 do
            time_spent = 0
            distance_traveled = 0

            time_remaining = route_duration_max ? route_duration_max : nil

            route_coords = [[destination_coords[0], 0]]

            resolve_nearest_coord = ->() {
              matrix.nearest_coord(route_coords.last[1]) do |time_to_coord, distance_to_coord, index|
                new_time_spent = time_spent + time_to_coord + UNLOAD_TIME
                new_distance_traveled = distance_traveled + distance_to_coord

                if (!enforce_route_distance_max || route_distance_max > new_distance_traveled) && (!enforce_route_duration_max || route_duration_max > new_time_spent)
                  time_spent = new_time_spent
                  distance_traveled = new_distance_traveled

                  coords_remaining -= 1
                  time_remaining -= (time_to_coord + UNLOAD_TIME) if enforce_route_duration_max

                  route_coords << [destination_coords[index], index]
                  true
                else
                  time_remaining = 0
                  false
                end
              end
            }

            if enforce_route_duration_max
              while time_remaining > 0 do
                resolve_nearest_coord.call
              end
            else
              resolve_nearest_coord.call
            end

            routes_array.push(route_coords)
          end

          routes_array
        end

        def calc_sub_matrix(start_coords, dest_coords)
          height = start_coords.size
          width = dest_coords.size

          sub_matrix = Array.new(height) { Array.new(width) }
          _, response = RoutingService.calculate_matrix(start_coords, dest_coords)

          response['matrix_entires'].each do |entry|
            start = entry['start_index']
            destination = entry['destination_index']

            sub_matrix[start][destination] = {
              cost_factor: entry['summary']['cost_factor'],
              distance: entry['summary']['distance'],
              time: entry['summary']['travel_time'],
            }
          end

          sub_matrix
        end
      end
    end
  end
end
