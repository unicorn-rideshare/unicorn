object @dispatcher => nil

attributes :id,
           :name

node(:user_id) do |dispatcher|
  dispatcher.user_id.nil? ? nil : dispatcher.user_id
end

node(:profile_image_url) do |dispatcher|
  dispatcher.user_id.nil? ? nil : dispatcher.user.profile_image_url
end

node(:contact) do |dispatcher|
  partial 'contacts/show', object: dispatcher.contact
end
