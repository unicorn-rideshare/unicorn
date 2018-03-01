module Unicorn
  module Routing
    class DistTimeMatrix
      attr_reader :values

      def initialize(size)
        @used_values = []
        @values = []

        initialize_empty_values(size)
      end

      def size
        @values.size
      end

      def buildup(height_border, width_border, sub_matrix)
        sub_matrix.each_with_index do |line, i|
          line.each_with_index do |cell, j|
            @values[height_border + i][width_border + j] = cell
          end
        end
      end

      def nearest_coord(index)
        current_distances = @used_values[index].collect { |d| d[:distance] }
        current_times = @used_values[index].collect { |d| d[:time] }
        route_point = current_distances.compact.min
        next_point_index = current_distances.index(route_point)
        time = current_times[next_point_index]
        flag = yield(time, route_point, next_point_index)
        @used_values.map! { |d| d[next_point_index][:distance] = 20000000.0; d } if flag
      end

      def process
        @used_values = Array.new(size) { Array.new(size) }
        for i in 0..@values.size - 1 do
          for j in 0..@values.size - 1 do
            @used_values[i][j] = {
                distance: @values[i][j] ? @values[i][j][:distance] : nil,
                time: @values[i][j] ? @values[i][j][:time] : nil
            }
          end
        end

        @used_values.each do |v|
          v[0][:distance] = 20000000.0
        end
      end

      private

      def initialize_empty_values(size)
        @values = Array.new(size) { Array.new(size) }
      end
    end
  end
end
