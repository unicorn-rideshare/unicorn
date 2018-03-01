module Api
  class ProductsController < Api::ApplicationController
    load_and_authorize_resource

    around_action :attach_image, only: [:create, :update], unless: lambda { params[:product_image_url].nil? }
    before_action :parse_data, only: [:create, :update], unless: lambda { params[:data].nil? }

    def index
      @products = filtered_products
      respond_with(:api, @products)
    end

    def show
      @include_variants = params[:include_variants] ? params[:include_variants].to_s.match(/^true$/i) : true
      respond_with(:api, @product)
    end

    def create
      @product.save && true
      respond_with(:api, @product, template: 'api/products/show', status: :created)
    end

    def update
      @product.update(product_params)
      respond_with(:api, @product)
    end

    def destroy
      @product.destroy
      respond_with(:api, @product)
    end

    private

    def attach_image
      product_image_url = params.delete(:product_image_url)
      yield
      @product.attachments.create(user: current_user,
                                  source_url: product_image_url,
                                  tags: %w(profile_image default)) if product_image_url && @product && @product.valid?
    end

    def filtered_products
      @include_variants = params[:include_variants] ? params[:include_variants].to_s.match(/^true$/i) : false
      @products = @products.top_level unless @include_variants
      @products = filter_by(@products, indexes)
    end

    def indexes
      [:company_id, :gtin, :tier, :product_id]
    end

    def parse_data
      @product.data = params.delete(:data)
    end

    def product_params
      params.permit(
          :company_id, :gtin, :data, :tier, :product_id
      )
    end
  end
end
