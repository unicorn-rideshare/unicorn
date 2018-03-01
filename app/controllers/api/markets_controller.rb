module Api
  class MarketsController < Api::ApplicationController
    load_and_authorize_resource

    def index
      @markets = filter_by(@markets, indexes)
      respond_with(:api, @markets)
    end

    def show
      respond_with(:api, @market)
    end

    def create
      @market.save && true
      respond_with(:api, @market, template: 'api/markets/show', status: :created)
    end

    def update
      @market.update(market_params)
      respond_with(:api, @market)
    end

    def destroy
      @market.destroy
      respond_with(:api, @market)
    end

    private

    def indexes
      [:company_id, :google_place_id]
    end

    def market_params
      params.permit(
          :company_id, :name, :google_place_id
      )
    end
  end
end
