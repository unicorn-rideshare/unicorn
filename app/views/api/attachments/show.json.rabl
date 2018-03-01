object @attachment => nil

attributes :id,
           :display_url,
           :description,
           :latitude,
           :longitude,
           :key,
           :metadata,
           :mime_type,
           :parent_attachment_id,
           :public,
           :status,
           :tags,
           :url,
           :user_id

node(:attachable_id) do |attachment|
  attachment.attachable_id || attachment.notifiable.try(:id)
end

node(:attachable_type) do |attachment|
  (attachment.attachable_type || attachment.notifiable.class.name).try(:underscore)
end

node(:created_at) do |attachment|
  attachment.created_at.iso8601
end

node(:user) do |attachment|
  partial 'users/show', object: attachment.user
end if @include_user
