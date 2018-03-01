module Api
  class CheckinsController < Api::ApplicationController
    load_and_authorize_resource

    def index
      @checkins = filter_by(@checkins, indexes)
      respond_with(:api, @checkins)
    end

    def create
      @checkin.save && true
      respond_with(:api, @checkin, template: 'api/checkins/show', status: :created)
    end

    def destroy
      @checkin.destroy
      respond_with(:api, @checkin)
    end

    private

    def checkin_params
      params.permit(:checkin_at, :latitude, :longitude, :heading, :reason)
    end

    def indexes
      [:locatable_id, :locatable_type]
    end
  end
end
