module Geocodable
  extend ActiveSupport::Concern

  included do
    attr_accessor :skip_geocode

    validates :latitude, readonly: true, unless: 'self.skip_geocode || @geocode_changed'

    validates :longitude, readonly: true, unless: 'self.skip_geocode || @geocode_changed'

    before_save :sanitize_address, if: lambda { self.address_changed? }

    before_save :update_geometry, if: lambda { self.respond_to?(:geom) && self.coordinates_changed? }

    before_save :update_timezone, if: lambda { self.coordinates_changed? }

    after_save :schedule_geocode, if: lambda { self.skip_geocode || self.address_changed? }
  end

  def address
    "#{address1}\n#{address2? ? "#{address2}\n" : ''}#{city}, #{state} #{zip}" if address1 && city && state && zip
  end

  def geocode_and_save
    coordinates = (GeocodingService.geocode(street_number, street, city, state, zip).first['geometry']['location'] rescue nil) if address
    self.latitude, self.longitude = [coordinates['latitude'], coordinates['longitude']] if coordinates
    @geocode_changed = true
    save!
    @geocode_changed = false
  end

  def address_changed?
    (%w(address1 address2 city state zip) & changed_attributes.keys).present?
  end

  def coordinates_changed?
    longitude_changed? || latitude_changed?
  end

  private

  def street_number
    number = address1.match(/^\d+/) if address1
    number = address2.match(/^\d+/) if number.nil? && address2
    number[0] if number
  end

  def street
    number_str = street_number
    address1[number_str.length..address1.length].strip if number_str
  end

  def schedule_geocode
    Resque.enqueue(GeocodeContactJob, id)
  end

  def sanitize_address
    %w(address1 address2 city state zip).each do |key|
      value = send("#{key}")
      send("#{key}=", nil) if value && value.gsub(/\s+/, '').length == 0
    end
  end

  def update_geometry
    result = self.class.connection.execute("SELECT ST_SetSRID(ST_MakePoint(#{longitude}, #{latitude}), 4326) as geom").first
    self.geom = result ? result['geom'] : nil
  end

  def update_timezone
     tz = Timezone::Zone.new(latlon: [latitude, longitude]) rescue nil
     self.time_zone = TimeZone.find(tz.active_support_time_zone) if tz
  end
end
