class GeocodingService
  class << self
    def tourguide
      Provide::Services::Tourguide.new((ENV['TOURGUIDE_API_SCHEME'] || 'http'), ENV['TOURGUIDE_API_HOST'])
    end

    def geocode(street_number, street, city, state, postal_code)
      _, response = tourguide.geocode(street_number, street, city, state, postal_code)
      response
    end

    def reverse_geocode(coordinates)
      _, response = tourguide.reverse_geocode(coordinates.latitude, coordinates.longitude)
      response
    end
  end
end
