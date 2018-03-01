module Api
  class CompaniesController < Api::ApplicationController
    load_and_authorize_resource

    around_action :create_stripe_credit_card, only: [:create, :update], unless: lambda { params[:stripe_card_token].nil? || params[:stripe_plan_id] }
    around_action :create_stripe_subscription, only: [:create, :update], unless: lambda { params[:stripe_plan_id].nil? }
    around_action :apply_stripe_coupon_code, only: [:create, :update], unless: lambda { params[:stripe_coupon_code].nil? }

    def index
      @include_stripe_customer = params[:include_stripe_customer].to_s.match(/^true$/i)

      @companies = filter_by(@companies.greedy, indexes)
      respond_with(:api, @companies)
    end

    def show
      @include_stripe_customer = params[:include_stripe_customer].to_s.match(/^true$/i)
      respond_with(:api, @company)
    end

    def create
      @company.save && true
      respond_with(:api, @company, template: 'api/companies/show', status: :created)
    end

    def update
      @company.update(company_params)
      respond_with(:api, @company)
    end

    def destroy
      @company.destroy
      respond_with(:api, @company)
    end

    private

    def apply_stripe_coupon_code
      stripe_coupon_code = params.delete(:stripe_coupon_code)
      yield
      @company.apply_stripe_coupon_code(stripe_coupon_code)
    end

    def company_params
      params[:contact_attributes] = params.delete(:contact) if params.key? :contact
      params[:name] = params[:contact_attributes][:name] if params[:contact_attributes]
      params.permit(
        { contact_attributes: permitted_contact_params }, :name, :user_id
      )
    end

    def create_stripe_credit_card
      stripe_card_token = params.delete(:stripe_card_token)
      yield
      @company.create_stripe_credit_card(stripe_card_token)
    end

    def create_stripe_subscription
      stripe_card_token = params.delete(:stripe_card_token)
      stripe_plan_id = params.delete(:stripe_plan_id)
      yield
      @company.create_stripe_subscription(stripe_plan_id, stripe_card_token)
    end

    def indexes
      [:user_id]
    end
  end
end
