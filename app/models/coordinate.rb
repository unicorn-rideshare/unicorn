class Coordinate
  attr_reader :latitude, :longitude

  def initialize(latitude, longitude)
    @latitude = latitude
    @longitude = longitude
  end

  def ==(coordinate)
    coordinate.is_a?(Coordinate) && latitude.to_f == coordinate.latitude.to_f && longitude.to_f == coordinate.longitude.to_f
  end
  alias :eql? :==

  def hash
    [latitude, longitude].hash
  end

  def to_s
    "#{latitude},#{longitude}"
  end
end
