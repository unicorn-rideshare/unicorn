module Api
  class TimeZonesController < Api::ApplicationController
    def index
      @time_zones = TimeZone.all
      respond_with(:api, @time_zones)
    end
  end
end
