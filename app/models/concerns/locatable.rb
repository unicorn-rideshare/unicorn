module Locatable
  extend ActiveSupport::Concern

  included do
    has_many :checkins,
             as: :locatable,
             after_add: :checkin_added,
             dependent: :destroy

    def interpolated_checkin_coordinates(starting_at, ending_at = DateTime.now)
      ending_at ||= DateTime.now

      query = <<-EOF
        SELECT ST_AsGeoJSON(ST_Multi(ST_MakeLine(geom ORDER BY checkin_at))) as json
        FROM checkins
        WHERE locatable_id = #{id} AND checkin_at >= '#{starting_at.utc.to_s(:db)}' AND checkin_at <= '#{ending_at.utc.to_s(:db)}'
        LIMIT 1
      EOF

      result = self.class.connection.execute(query).first['json']
      result = JSON.parse(result) if result rescue nil
      result = result['coordinates'].first if result && result['coordinates'] && result['coordinates'].size > 0
      result = result.map(&:reverse) if result
      result || []
    end

    def last_checkin
      checkins.limit(1).first
    end

    private

    def checkin_added(checkin)
      # no-op by default
    end
  end
end
