module Api
  class OriginsController < Api::ApplicationController
    load_and_authorize_resource

    def index
      @origins = filter_by(@origins.includes(:contact), indexes)
      respond_with(:api, @origins)
    end

    def show
      respond_with(:api, @origin)
    end

    def create
      @origin.save && true
      respond_with(:api, @origin, template: 'api/origins/show', status: :created)
    end

    def update
      @origin.update(origin_params)
      respond_with(:api, @origin)
    end

    def destroy
      @origin.destroy
      respond_with(:api, @origin)
    end

    private

    def indexes
      [:market_id, :warehouse_number]
    end

    def origin_params
      params[:contact_attributes] = params.delete(:contact) if params.key? :contact
      params.permit(
          :market_id, :warehouse_number, { contact_attributes: permitted_contact_params }
      )
    end
  end
end
