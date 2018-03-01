object @provider => nil

attributes :id,
           :name,
           :category_ids,
           :available,
           :last_checkin_latitude,
           :last_checkin_longitude,
           :last_checkin_heading

node(:user_id) do |provider|
  provider.user_id.nil? ? nil : provider.user_id
end

node(:profile_image_url) do |provider|
  provider.user_id.nil? ? nil : provider.user.profile_image_url
end

node(:contact) do |provider|
  partial 'contacts/show', object: provider.contact
end

node(:last_checkin_at) do |provider|
  provider.last_checkin_at.nil? ? nil : provider.last_checkin_at.iso8601
end
