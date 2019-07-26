class GeocodingService
  class << self
    def tourguide
      Provide::Services::Tourguide.new((ENV['TOURGUIDE_API_SCHEME'] || 'http'), ENV['TOURGUIDE_API_HOST'], ENV['PROVIDE_APPLICATION_API_TOKEN'])
    end

    def geocode(street_number, street, city, state, postal_code)
      _, _, response = tourguide.geocode(street_number, street, city, state, postal_code)
      response
    end

    def reverse_geocode(coordinates)
      _, _, response = tourguide.reverse_geocode(coordinates.latitude, coordinates.longitude)
      response
    end
  end
end
