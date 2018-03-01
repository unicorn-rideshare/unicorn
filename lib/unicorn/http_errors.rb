module Unicorn
  module HttpErrors
    extend ActiveSupport::Concern

    class BadRequest < RuntimeError
      def initialize(errors = nil)
        @errors = errors
      end

      def json
        return {} unless @errors
        { errors: @errors }
      end
    end

    class UnprocessableEntity < RuntimeError
      def initialize(model_instance = nil)
        @model_instance = model_instance
      end

      def json
        return {} unless @model_instance
        { errors: @model_instance.errors }
      end
    end

    included do
      rescue_from ActiveRecord::RecordNotFound do
        render status: :not_found, json: { } if json_request?
        render status: :not_found unless json_request?
      end

      rescue_from ActiveRecord::RecordNotUnique do
        render status: :conflict, json: { } if json_request?
        render status: :conflict unless json_request?
      end

      rescue_from CanCan::AccessDenied do
        render status: :forbidden, json: { } if json_request?
        render status: :forbidden unless json_request?
      end

      rescue_from BadRequest do |ex|
        render status: :bad_request, json: ex.json if json_request?
        render status: :bad_request unless json_request?
      end

      rescue_from UnprocessableEntity do |ex|
        render status: :unprocessable_entity, json: ex.json if json_request?
        render status: :unprocessable_entity unless json_request?
      end
    end
  end
end
