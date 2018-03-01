module Api
  class TasksController < Api::ApplicationController
    load_and_authorize_resource

    before_action :handle_status_transition, only: [:create, :update], unless: lambda { params[:status].nil? }
    around_action :delegate_task, only: [:create, :update], unless: lambda { params[:provider_id].nil? }

    def index
      @tasks = filter_by(filtered_tasks, indexes)
      respond_with(:api, @tasks)
    end

    def create
      @task.user = current_user
      @task.save && true
      respond_with(:api, @task, template: 'api/tasks/show', status: :created)
    end

    def update
      @task.update(task_params)
      respond_with(:api, @task)
    end

    def destroy
      @task.destroy
      respond_with(:api, @task)
    end

    private

    def delegate_task
      yield
    end

    def filtered_tasks
      @tasks = @tasks.where(work_order_id: nil) if params[:exclude_work_orders].to_s.match(/^true$/i)
      filter_by(@tasks, indexes)
    end

    def task_params
      params.permit(:company_id, :category_id, :task_id, :provider_id,
                    :job_id, :work_order_id, :name, :description, :status)
    end

    def indexes
      [:user_id, :company_id, :category_id, :task_id, :provider_id, :job_id, :work_order_id, :status]
    end
  end
end
