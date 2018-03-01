module Api
  class DevicesController < Api::ApplicationController
    load_and_authorize_resource

    def index
      @devices = filter_by(@devices, indexes)
      respond_with(:api, @devices)
    end

    def show
      respond_with(:api, @device)
    end

    def create
      @device.save && true
      respond_with(:api, @device, template: 'api/devices/show', status: :created)
    end

    def update
      @device.update(device_params)
      respond_with(:api, @device)
    end

    def destroy
      @device.destroy
      respond_with(:api, @device)
    end

    private

    def indexes
      [:user_id, :apns_device_id, :gcm_registration_id]
    end

    def device_params
      params.permit(
          :user_id, :apns_device_id, :gcm_registration_id, :bundle_id
      )
    end
  end
end
