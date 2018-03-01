object @checkin => nil

attributes :locatable_id,
           :reason,
           :latitude,
           :longitude,
           :heading

node(:locatable_type) do |checkin|
  checkin.locatable_type.downcase
end

node(:checkin_at) do |checkin|
  checkin.checkin_at.iso8601
end
