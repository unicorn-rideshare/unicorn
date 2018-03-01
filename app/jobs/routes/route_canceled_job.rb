class RouteCanceledJob
  @queue = :high

  class << self
    def perform(route_id)
      route = Route.find(route_id)

      route.legs.map(&:work_order).each do |work_order|
        work_order.cancel! unless work_order.nil? || work_order.disposed?
      end
    end
  end
end
