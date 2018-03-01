object @message => nil

attributes :id,
           :body,
           :media_url,
           :recipient_id,
           :sender_id

node(:created_at) do |message|
  message.created_at.iso8601
end

node(:recipient_name) do |message|
  message.recipient.name
end

node(:sender_name) do |message|
  message.sender.name
end

node(:sender_profile_image_url) do |message|
  message.sender.profile_image_url
end
