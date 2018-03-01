module Api
  class PaymentMethodsController < Api::ApplicationController
    load_and_authorize_resource

    around_action :tokenize_card, only: [:create]

    def index
      @payment_methods = filter_by(@payment_methods, indexes)
      respond_with(:api, @payment_methods)
    end

    def show
      respond_with(:api, @payment_method)
    end

    def create
      @payment_method.user = current_user
      @payment_method.save && true
      respond_with(:api, @payment_method, template: 'api/payment_methods/show', status: :created)
    end

    def destroy
      @payment_method.destroy
      respond_with(:api, @payment_method)
    end

    def charge
      payment_method = (PaymentMethod.where(id: params[:payment_method_id], user_id: current_user.id).first rescue raise NotFound)
      payment_method.charge(params[:amount].to_i, params[:description]) rescue raise BadRequest
      head :no_content
    end

    private

    def indexes
      [:user_id]
    end

    def payment_method_params
      params.permit(
          :user_id, :type
      )
    end

    def tokenize_card
      begin
        token = PaymentService.validate_and_tokenize_card(params.delete(:card_number),
                                                          params.delete(:exp_month).try(:to_i),
                                                          params.delete(:exp_year).try(:to_i),
                                                          params.delete(:cvc))
      rescue Stripe::StripeError => e
        errkey = e.code rescue 'card'
        raise BadRequest.new({errkey => [e.message]})
      end

      @payment_method.stripe_token = token.id
      @payment_method.stripe_credit_card_id = token.card.id
      @payment_method.brand = token.card.brand
      @payment_method.last4 = token.card.last4
      yield
    end
  end
end
