module Api
  class CategoriesController < Api::ApplicationController
    load_and_authorize_resource

    def index
      @categories = filtered_categories
      respond_with(:api, @categories)
    end

    def show
      respond_with(:api, @category)
    end

    def create
      @category.save && true
      respond_with(:api, @category, template: 'api/categories/show', status: :created)
    end

    def update
      @category.update(category_params)
      respond_with(:api, @category)
    end

    def destroy
      @category.destroy
      respond_with(:api, @category)
    end

    private

    def category_params
      params.permit(
          :company_id, :name, :abbreviation
      )
    end

    def coordinate
      @coordinate ||= begin
        params[:latitude] && params[:longitude] ? Coordinate.new(params[:latitude], params[:longitude]) : nil
      end
    end

    def filtered_categories
      @categories = filter_by(@categories.greedy, indexes)
      @categories = @categories.by_market(params[:market_id]) if params[:market_id]
      @categories = @categories.nearby(coordinate, (params[:radius].to_i rescue 50)) if coordinate  # TODO: make default radius in miles configurable
      @categories
    end

    def indexes
      [:company_id]
    end
  end
end
