class RouteScheduledJob
  @queue = :high

  class << self
    def perform(route_id)
      route = Route.find(route_id)

      Resque.remove_delayed(RouteStartedStatusCheckupJob, route.id)
      Resque.enqueue_at(route.scheduled_start_at.end_of_day, RouteStartedStatusCheckupJob, route.id) unless route.scheduled_start_at.nil?

      RoutingService.generate_route(route, route.work_orders)
    end
  end
end
