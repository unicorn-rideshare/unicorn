class GeocodeMarketJob
  @queue = :high

  class << self
    def perform(market_id)
      market = Market.unscoped.find(market_id) rescue nil
      return unless market && market.google_place_id

      place = RoutingService.place_details(market.google_place_id)
      location = place['geometry']['location'] rescue nil
      coordinate = Coordinate.new(location['latitude'], location['longitude']) rescue nil
      market.update_attribute(:time_zone_id, RoutingService.timezone(coordinate).name) rescue nil

      result = market.class.connection.execute("SELECT ST_SetSRID(ST_MakePoint(#{coordinate.longitude}, #{coordinate.latitude}), 4326) as geom").first rescue nil
      market.update_attribute(:geom, result['geom']) rescue nil
    end
  end
end
