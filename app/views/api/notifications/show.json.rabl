object @notification => nil

attributes :id,
           :recipient_id,
           :type,
           :slug

node(:delivered_at) do |notification|
  notification.delivered_at ? notification.delivered_at.iso8601 : nil
end

node(:suppressed_at) do |notification|
  notification.suppressed_at ? notification.suppressed_at.iso8601 : nil
end
