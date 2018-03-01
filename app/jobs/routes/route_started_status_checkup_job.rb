class RouteStartedStatusCheckupJob
  @queue = :high

  class << self
    def perform(route_id)
      route = Route.find(route_id)
      case route.status.to_sym
        when :scheduled
          route.cancel!
        else
          # no-op for now
      end
    end
  end
end
