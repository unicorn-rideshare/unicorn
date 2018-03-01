object @contact => nil

attributes :id,
           :name,
           :address1,
           :address2,
           :city,
           :state,
           :zip,
           :email,
           :phone,
           :fax,
           :mobile,
           :website,
           :time_zone_id,
           :description,
           :data

node(:latitude)  { |contact| contact.latitude? ? contact.latitude.to_f : nil }
node(:longitude) { |contact| contact.longitude? ? contact.longitude.to_f : nil }

node(:dob) do |contact|
  contact.dob ? contact.dob.iso8601 : nil
end
