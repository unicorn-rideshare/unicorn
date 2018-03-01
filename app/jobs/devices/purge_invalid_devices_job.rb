class PurgeInvalidDevicesJob
  @queue = :high

  class << self
    def perform
      self.purge_invalid_apns_devices
    end

    def purge_invalid_apns_devices
      invalid_apns_device_ids = Rails.application.config.houston_client.devices
      invalid_apns_device_ids.each { |device_id| Device.where(apns_device_id: "<#{device_id}>").first.try(:delete) if device_id }
    end
  end
end
