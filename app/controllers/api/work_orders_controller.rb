module Api
  class WorkOrdersController < Api::ApplicationController
    skip_before_action :authenticate_user!, :authenticate_token!, only: :call
    load_and_authorize_resource except: [:call]
    load_resource only: :call

    around_action :accept_invitation, only: :update, unless: lambda { params[:invitation_token].nil? }
    around_action :append_to_route, only: :create, unless: lambda { params[:route_id].nil? }
    around_action :associate_with_job, only: :create, unless: lambda { params[:job_id].nil? }
    around_action :associate_with_user, only: :create, unless: lambda { (current_user rescue nil).nil? || params[:company_id].present? || params[:customer_id].present? }
    around_action :update_config, only: [:create, :update], unless: lambda { params[:config].nil? }
    before_action :handle_status_transition, only: [:create, :update], unless: lambda { params[:status].nil? }
    before_action :confirm_providers, only: [:update], unless: lambda { params[:work_order_providers].nil? }
    around_action :add_initial_supervisor, only: :create
    around_action :update_supervisors, only: [:create, :update], unless: lambda { params[:supervisors].nil? }
    before_action :create_manifest, only: [:create, :update], unless: lambda { !includes_gtins_ordered? }
    before_action :update_manifest, only: [:update], unless: lambda { !valid_manifest_update? }
    before_action :validate_manifest_params, only: [:update], unless: lambda { !includes_gtins_delivered? && !includes_gtins_rejected? }

    def index
      @api = true
      @include_jobs = params[:include_jobs] ? params[:include_jobs].to_s.match(/^true$/i) : false
      @include_expenses = params[:include_expenses].to_s.match(/^true$/i)
      @include_estimated_cost = params[:include_estimated_cost].to_s.match(/^true$/i) || @include_expenses
      @include_products = params[:include_products] ? params[:include_products].to_s.match(/^true$/i) : false
      @include_work_order_providers = params[:include_work_order_providers] ? params[:include_work_order_providers].to_s.match(/^true$/i) : false
      @include_checkin_coordinates = params[:include_checkin_coordinates].to_s.match(/^true$/i)
      @work_orders = filtered_work_orders
      respond_with(:api, @work_orders)
    end

    def show
      @api = true
      @include_job = params[:include_job] ? params[:include_job].to_s.match(/^true$/i) : false
      @include_expenses = params[:include_expenses].to_s.match(/^true$/i)
      @include_estimated_cost = params[:include_estimated_cost].to_s.match(/^true$/i) || @include_expenses
      @include_products = params[:include_products] ? params[:include_products].to_s.match(/^true$/i) : false
      @include_supervisors = params[:include_supervisors].to_s.match(/^true$/i)
      @include_work_order_providers = params[:include_work_order_providers] ? params[:include_work_order_providers].to_s.match(/^true$/i) : false
      @include_checkin_coordinates = params[:include_checkin_coordinates].to_s.match(/^true$/i)
      respond_with(:api, @work_order)
    end

    def create
      @work_order.save && true
      respond_with(:api, @work_order, template: 'api/work_orders/show', status: :created)
    end

    def update
      @work_order.update(work_order_params)
      respond_with(:api, @work_order)
    end

    def destroy
      @work_order.destroy
      respond_with(:api, @work_order)
    end

    def call
      if TwilioService.verify_signature(request) # rubocop:disable GuardClause
        customer = @work_order.customer
        company = @work_order.company
        response = Twilio::TwiML::Response.new do |body|
          body.Say "Hello #{customer.name}, this is #{company.name}. Wassup?"
        end
        render xml: response.text
      end
    end

    private

    def accept_invitation
      invitation_token = params.delete(:invitation_token)
      invitations = @work_order.work_order_providers.select { |work_order_provider| current_user.provider_ids.include?(work_order_provider.provider_id) }.map(&:invitations).flatten
      invitation = invitations.select { |_invitation| _invitation.token == invitation_token }.first if invitations
      raise UnprocessableEntity unless invitation
      invitation.accept
      yield
    end

    def append_to_route
      yield
      route = Route.find(params.delete(:route_id))
      raise UnprocessableEntity unless route
      route.legs.create(work_order: @work_order)
    end

    def associate_with_job
      yield
      job = Job.find(params.delete(:job_id))
      raise UnprocessableEntity unless job
      raise CanCan::AccessDenied unless job.company_id == @work_order.company_id
      job.work_orders << @work_order
    end

    def associate_with_user
      @work_order.user_id = current_user.id
      yield
    end

    def indexes
      [:category_id, :company_id, :customer_id, :floorplan_id, :job_id, :route_leg_id, :user_id]
    end

    def work_order_params
      has_materials = params.key? :materials
      has_work_order_providers = params.key? :work_order_providers
      params[:work_order_products_attributes] = params.delete(:materials) if has_materials
      params[:work_order_products_attributes] ||= [] if has_materials
      params[:work_order_providers_attributes] = params.delete(:work_order_providers).map { |wop| wop[:provider_id] = wop[:provider_id].to_i } if has_work_order_providers && params[:work_order_providers]
      params[:work_order_providers_attributes] ||= [] if has_work_order_providers
      params.permit(
        :category_id, :company_id, :customer_id, :floorplan_id, :job_id, :user_id, :description,
        :status, :estimated_distance, :estimated_duration, :provider_rating, :user_rating,
        :scheduled_start_at, :scheduled_end_at, :preferred_scheduled_start_date, :started_at,
        :ended_at, :due_at, :priority, :config,
        work_order_products_attributes: [:id, :job_product_id, :quantity, :price],
        work_order_providers_attributes: [:id, :provider_id, :confirmed_at, :estimated_duration, :hourly_rate, :flat_fee]
      )
    end

    def confirm_providers
      _confirm_work_order_provider = ->(_provider_id, _confirmed_at = DateTime.now) {
        existing_work_order_provider = @work_order.work_order_providers.where(provider_id: _provider_id).first
        existing_work_order_provider.confirm(_confirmed_at) rescue nil
      }
      if current_ability.is_a?(ProviderAbility)
        provider_id = current_user.providers.first.id if current_user.providers.count == 1 # FIXME-- resolve the current provider to confirm
        _confirm_work_order_provider.call(provider_id)
      else
        work_order_providers = params[:work_order_providers]
        work_order_providers.each do |work_order_provider|
          provider_id = (work_order_provider[:provider] ? work_order_provider[:provider][:id] : work_order_provider[:provider_id]).to_i rescue nil
          _confirm_work_order_provider.call(provider_id, work_order_provider[:confirmed_at])
        end if work_order_providers
      end
    end

    def create_manifest
      gtins_ordered = params.delete(:gtins_ordered) || []
      products_ordered = gtins_ordered.map { |gtin| @work_order.company.products.where(gtin: gtin).first }
      raise BadRequest unless products_ordered

      @work_order.transaction do
        @work_order.items_ordered = []
        @work_order.items_ordered = products_ordered
      end
    end

    def includes_gtins_ordered?
      params.has_key?(:gtins_ordered)
    end

    def includes_gtins_delivered?
      params.has_key?(:gtins_delivered)
    end

    def includes_gtins_rejected?
      params.has_key?(:gtins_rejected)
    end

    def partial_manifest_update?
      includes_gtins_delivered? || includes_gtins_rejected? && !(includes_gtins_delivered? && includes_gtins_rejected?)
    end

    def update_config
      config = params[:config]
      @work_order.config = config.with_indifferent_access
      yield
    end

    def update_manifest # FIXME-- determine how to clean up the business logic contained herein
      gtins_delivered = params.delete(:gtins_delivered) || []
      products_delivered = gtins_delivered.map { |gtin| @work_order.company.products.where(gtin: gtin).first }
      raise BadRequest unless products_delivered

      gtins_rejected = params.delete(:gtins_rejected) || []
      products_rejected = gtins_rejected.map { |gtin| @work_order.company.products.where(gtin: gtin).first }
      raise BadRequest unless products_rejected

      @work_order.transaction do
        @work_order.items_delivered = []
        @work_order.items_delivered = products_delivered

        @work_order.items_rejected = []
        @work_order.items_rejected = products_rejected
      end
    end

    def add_initial_supervisor
      yield
      current_user.add_role(:provider, @work_order)
      current_user.add_role(:supervisor, @work_order)
    end

    def update_supervisors
      supervisors = params.key?(:supervisors) ? params.delete(:supervisors).map { |supervisor| User.where(id: supervisor[:id]).first } : []
      raise UnprocessableEntity if supervisors.include?(nil)
      supervisors.select! do |supervisor|
        valid_company_provider = Provider.where(user_id: supervisor[:id], company_id: @work_order.company_id).first
        valid_company_admin = valid_company_provider ? false : User.where(id: supervisor[:id]).first.company_ids.include?(@work_order.company_id)
        valid_company_provider || valid_company_admin
      end
      yield
      @work_order.supervisors = supervisors
    end

    def valid_manifest_update?
      includes_gtins_delivered? && includes_gtins_rejected?
    end

    def validate_manifest_params
      raise UnprocessableEntity if partial_manifest_update?
    end

    def filtered_work_orders
      @work_orders = @work_orders.by_provider_id(params[:provider_id]) if params[:provider_id]
      @work_orders = @work_orders.ordered_by_started_at_desc if params[:sort_started_at_desc].to_s.match(/^true$/i)
      @work_orders = @work_orders.ordered_by_priority_and_due_at_asc if params[:sort_priority_and_due_at_asc].to_s.match(/^true$/i)
      @work_orders = @work_orders.greedy if params[:greedy].to_s.match(/^true$/i)

      filter = filter_by(@work_orders, indexes)

      date_range = params[:date_range] ? params[:date_range].split(/\.\./) : nil
      if date_range && date_range.length > 0
        range_start = date_range[0].length > 0 ? date_range[0] : nil
        range_end = (date_range[1] && date_range[1].length > 0) ? date_range[1] : nil
        if range_start && range_end && range_start == range_end
          filter = filter.on(range_start)
        else
          is_date_only = ->(str) { str.to_s.match(/^\d{4}-\d{2}-\d{2}$/) }
          filter = is_date_only.call(range_start) ? filter.on_or_after(range_start) : filter.after_inclusive(range_start) if range_start
          filter = is_date_only.call(range_end) ? filter.on_or_before(range_end) : filter.before_inclusive(range_end) if range_end
        end
      end

      filter = filter.where(route_leg: nil) if params[:exclude_routes].to_s.match(/^true$/i)
      @total_results_count = filter.limit(nil).offset(nil).count if paginate?
      filter
    end
  end
end
