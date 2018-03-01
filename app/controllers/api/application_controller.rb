module Api
  class ApplicationController < ::ApplicationController
    before_action :authenticate_token!

    respond_to :json

    def render(*args)
      super
      response.headers['x-api-status'] = status.to_s
      pagination_response_headers.each_pair { |name, value| response.headers[name] = value } if paginate?
    end

    private

    # FIXME: make this filtering business logic a mixin
    def filter_by(collection, indexes = [])
      conditions = indexes.each_with_object({}) do |index, hash|
        index_params = params_for_index(index)
        hash.merge!(index_params)
      end
      criteria = collection
      conditions.keys.map do |key|
        or_syntax = conditions[key].match(/\|/)
        criteria = criteria.where("#{key} IN (:#{key})", key => conditions[key].split(/\|/)) if or_syntax
        criteria = criteria.where(key => conditions[key]) unless or_syntax
      end
      requested_statuses = params[:status] ? params[:status].split(/,/).map(&:strip).map(&:to_sym) : nil
      criteria = criteria.by_status(requested_statuses) if requested_statuses && criteria.respond_to?(:by_status)
      criteria = criteria.query(params[:q]) if query? && criteria.respond_to?(:query)
      if criteria && paginate?
        @total_results_count = criteria.count
        criteria = criteria.limit(rpp).offset((page - 1) * rpp)
      end
      criteria
    end

    # FIXME: make this state machine business logic a mixin
    def handle_status_transition
      model_class = controller_name.classify.split(/::/).last.constantize
      if model_class.respond_to?(:aasm)
        model_instance = instance_variable_get("@#{model_class.to_s.underscore}".to_sym)
        status = params.delete(:status)
        if status && model_instance
          return if model_instance.persisted? && status.downcase.to_sym == model_instance.status.downcase.to_sym
          permissible_events = model_instance.respond_to?(:permissible_events) ? model_instance.permissible_events(status.to_s) : []
          permissible_event = permissible_events.length > 0 ? "#{permissible_events[0]}!" : nil
          if permissible_event
            model_instance.send(permissible_event)
          else
            model_instance.errors.add(:status, I18n.t('errors.messages.invalid')) unless model_instance.new_record? && model_instance.is_permissible_status?(status)
            model_instance.errors.add(:status, I18n.t('errors.messages.not_included_in_list')) unless model_instance.is_permissible_status?(status)
            raise UnprocessableEntity.new(model_instance) unless model_instance.errors.size == 0
          end
        end
      end
    end

    def params_for_index(index)
      Array(index).each_with_object({}) do |key, hash|
        value = params[key]
        return hash unless value
        hash[key] = value
      end
    end

    # FIXME: make this pagination business logic a mixin
    def paginate?
      params[:page] && params[:rpp]
    end

    def pagination_response_headers
      {
        'x-total-results-count' => @total_results_count ? @total_results_count.to_s : nil
      }
    end

    def page
      params[:page].to_i
    end

    def rpp
      [(params[:rpp] || 10).to_i, 100].min
    end

    def query?
      params[:q]
    end

    # FIXME: make this contact related business logic a mixin
    def permitted_contact_params
      [
        :address1, :address2, :city, :dob, :email, :fax,
        :mobile, :name, :phone, :state, :time_zone_id, :zip,
        :website, :description
      ]
    end
  end
end
