object @customer => nil

attributes :id,
           :company_id,
           :name,
           :display_name,
           :customer_number

node(:contact) do |customer|
  partial 'contacts/show', object: customer.contact
end

node(:profile_image_url) do |customer|
  customer.user_id.nil? ? nil : customer.user.profile_image_url
end
