module Api
  class JobsController < Api::ApplicationController
    load_and_authorize_resource

    before_action :handle_status_transition, only: [:create, :update], unless: lambda { params[:status].nil? }
    around_action :update_supervisors, only: [:create, :update], unless: lambda { params[:supervisors].nil? }

    def index
      @jobs = filter_by(@jobs.greedy, indexes)
      @include_jobs = false
      @include_customer = params[:include_customer].to_s.match(/^true$/i)
      @include_expenses = params[:include_expenses].to_s.match(/^true$/i)
      @include_materials = params[:include_materials].to_s.match(/^true$/i)
      @include_work_orders = params[:include_work_orders].to_s.match(/^true$/i)
      @include_products = params[:include_products] ? params[:include_products].to_s.match(/^true$/i) : @include_work_orders
      respond_with(:api, @jobs)
    end

    def show
      @include_jobs = false
      @include_company = params[:include_company].to_s.match(/^true$/i)
      @include_customer = params[:include_customer] ? params[:include_customer].to_s.match(/^true$/i) : true
      @include_expenses = params[:include_expenses].to_s.match(/^true$/i)
      @include_materials = params[:include_materials].to_s.match(/^true$/i)
      @include_supervisors = params[:include_supervisors].to_s.match(/^true$/i)
      @include_work_orders = params[:include_work_orders].to_s.match(/^true$/i)
      @include_products = params[:include_products] ? params[:include_products].to_s.match(/^true$/i) : @include_work_orders
      @include_work_order_providers = params[:include_work_order_providers] ? params[:include_work_order_providers].to_s.match(/^true$/i) : @include_work_orders
      respond_with(:api, @job)
    end

    def create
      @job.save && true
      respond_with(:api, @job, template: 'api/jobs/show', status: :created)
    end

    def update
      @job.update(job_params)
      respond_with(:api, @job)
    end

    def destroy
      @job.destroy
      respond_with(:api, @job)
    end

    def tile
      job = Job.find(params[:job_id])
      current_ability.authorize!(:read, job)
      blueprint_id, z, x, y = [params[:blueprint_id], params[:z], params[:x], params[:y]]
      raise BadRequest unless blueprint_id && z && x && y
      tile = job.blueprint_tile(blueprint_id, z.to_i, x.to_i, y.to_i)
      raise ActiveRecord::RecordNotFound unless tile && tile.mime_type == 'image/png'
      redirect_to tile.url
    end

    private

    def job_params
      has_materials = params.key? :materials
      params[:job_products_attributes] = params.delete(:materials) if has_materials
      params[:job_products_attributes] ||= [] if has_materials
      params.permit(
          :company_id, :customer_id, :name, :status, :type, :quoted_price_per_sq_ft, :total_sq_ft, :wizard_mode,
          job_products_attributes: [:id, :product_id, :initial_quantity, :price]
      )
    end

    def indexes
      [:company_id, :customer_id, :job_id, :type]
    end

    def update_supervisors
      supervisors = params.key?(:supervisors) ? params.delete(:supervisors).map { |supervisor| Provider.where(id: supervisor[:id], company_id: @job.company_id).first } : []
      raise UnprocessableEntity if supervisors.include?(nil)
      yield
      @job.supervisors = supervisors
    end
  end
end
