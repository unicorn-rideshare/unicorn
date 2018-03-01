module Api
  class DispatcherOriginAssignmentsController < Api::ApplicationController
    load_and_authorize_resource

    def index
      @dispatcher_origin_assignments = filtered_dispatcher_origin_assignments
      respond_with(:api, @dispatcher_origin_assignments)
    end

    def show
      respond_with(:api, @dispatcher_origin_assignment)
    end

    def create
      @dispatcher_origin_assignment.save && true
      respond_with(:api, @dispatcher_origin_assignment, template: 'api/dispatcher_origin_assignments/show', status: :created)
    end

    def update
      @dispatcher_origin_assignment.update(dispatcher_origin_assignment_params)
      respond_with(:api, @dispatcher_origin_assignment)
    end

    def destroy
      @dispatcher_origin_assignment.destroy
      respond_with(:api, @dispatcher_origin_assignment)
    end

    private

    def indexes
      [:origin_id, :dispatcher_id]
    end

    def dispatcher_origin_assignment_params
      params.permit(
          :origin_id, :dispatcher_id, :start_date, :end_date
      )
    end

    def filtered_dispatcher_origin_assignments
      filter = filter_by(@dispatcher_origin_assignments, indexes)
      filter = filter.unscoped if params[:unscoped].to_s.match(/^true$/i)

      effective_on = params[:effective_on]
      filter = filter.where(origin_id: params[:origin_id]) if params[:origin_id]
      filter = filter.where(start_date: params[:start_date]) if params[:start_date]
      filter = filter.in_effect(effective_on) if effective_on

      if paginate?
        @total_results_count = filter.limit(nil).offset(nil).count
      end

      filter
    end
  end
end
