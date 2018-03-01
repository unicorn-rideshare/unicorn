object @device => nil

attributes :id,
           :apns_device_id,
           :gcm_registration_id,
           :bundle_id

node(:type) do |device|
  device.type.to_s
end
