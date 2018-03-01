module Api
  class CustomersController < Api::ApplicationController
    load_and_authorize_resource

    def index
      @customers = filter_by(@customers, indexes)
      respond_with(:api, @customers)
    end

    def show
      respond_with(:api, @customer)
    end

    def create
      @customer.save && true
      respond_with(:api, @customer, template: 'api/customers/show', status: :created)
    end

    def update
      @customer.update(customer_params)
      respond_with(:api, @customer)
    end

    def destroy
      @customer.destroy
      respond_with(:api, @customer)
    end

    private

    def customer_params
      params[:contact_attributes] = params.delete(:contact) if params.key? :contact
      params[:name] = params[:contact_attributes][:name] if params[:contact_attributes]
      params.permit(:company_id, :customer_number, { contact_attributes: permitted_contact_params }, :name, :user_id)
    end

    def indexes
      [:company_id, :user_id, :customer_number]
    end
  end
end
