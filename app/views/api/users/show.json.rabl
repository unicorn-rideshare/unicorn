object @user => nil

attributes :id,
           :name,
           :email,
           :profile_image_url,
           :company_ids,
           :default_company_id,
           :last_checkin_latitude,
           :last_checkin_longitude,
           :last_checkin_heading,
           :stripe_customer_id

node(:last_checkin_at) do |user|
  user.last_checkin_at.nil? ? nil : user.last_checkin_at.iso8601
end

node(:provider_ids) do |user|
  user.provider_ids.uniq
end

node(:wallets) do |user|
  partial 'wallets/index', object: user.wallets
end
