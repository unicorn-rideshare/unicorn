module Api
  class ProviderOriginAssignmentsController < Api::ApplicationController
    load_and_authorize_resource

    before_action :handle_status_transition, only: [:create, :update], unless: lambda { params[:status].nil? }

    def index
      @provider_origin_assignments = filtered_provider_origin_assignments
      respond_with(:api, @provider_origin_assignments)
    end

    def show
      respond_with(:api, @provider_origin_assignment)
    end

    def create
      @provider_origin_assignment.save && true
      respond_with(:api, @provider_origin_assignment, template: 'api/provider_origin_assignments/show', status: :created)
    end

    def update
      @provider_origin_assignment.update(provider_origin_assignment_params)
      respond_with(:api, @provider_origin_assignment)
    end

    def destroy
      @provider_origin_assignment.destroy
      respond_with(:api, @provider_origin_assignment)
    end

    private

    def indexes
      [:origin_id, :provider_id]
    end

    def provider_origin_assignment_params
      params.permit(
          :origin_id, :provider_id, :start_date, :end_date, :scheduled_start_at, :scheduled_end_at
      )
    end

    def filtered_provider_origin_assignments
      filter = filter_by(@provider_origin_assignments, indexes)
      filter = filter.unscoped if params[:unscoped].to_s.match(/^true$/i)

      effective_on = params[:effective_on]
      filter = filter.where(origin_id: params[:origin_id]) if params[:origin_id]
      filter = filter.where(start_date: Date.parse(params[:start_date])) if params[:start_date]
      filter = filter.in_effect(effective_on) if effective_on

      if paginate?
        @total_results_count = filter.limit(nil).offset(nil).count
      end

      filter
    end
  end
end
