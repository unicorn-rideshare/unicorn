module Api
  class ProvidersController < Api::ApplicationController
    around_action :associate_with_categories, only: [:create, :update], unless: lambda { params[:category_ids].nil? }
    around_action :associate_with_company, only: :create, unless: lambda { params[:company_id].nil? }
    around_action :associate_with_public, only: :create, if: lambda { params[:company_id].nil? }
    around_action :send_invitation, only: :create, if: :invite_user?
    load_and_authorize_resource except: [:availability]

    def index
      @providers = filtered_providers
      respond_with(:api, @providers)
    end

    def show
      respond_with(:api, @provider)
    end

    def create
      @provider.save && true
      respond_with(:api, @provider, template: 'api/providers/show', status: :created)
    end

    def update
      @provider.update(provider_params)
      respond_with(:api, @provider)
    end

    def destroy
      @provider.destroy
      respond_with(:api, @provider)
    end

    def availability
      date_range = params[:date_range] ? params[:date_range].split(/\.\./) : []
      params[:start_date] ||= date_range.count > 0 ? date_range[0] : nil
      params[:end_date] ||= date_range.count > 1 ? date_range[1] : nil
      params[:provider_ids] = params[:provider_ids].is_a?(Array) ? params[:provider_ids] : params[:provider_ids].split(/,/)
      availability = WorkOrderService.calculate_availability(params)
      render json: availability
    end

    private

    def filtered_providers
      @providers = @providers.by_category(params[:category_id].split(/\|/).map(&:to_i)) if params[:category_id]
      @providers = @providers.by_user(params[:user_id].split(/\|/).map(&:to_i)) if params[:user_id]
      @providers = @providers.standalone if params[:standalone].to_s.match(/^true$/i)
      @providers = @providers.available_for_hire if params[:available].to_s.match(/^true$/i)
      @providers = @providers.unavailable_for_hire if params[:available].to_s.match(/^false$/i)
      @providers = @providers.active if params[:active].to_s.match(/^true$/i)
      @providers = @providers.public_provider if params[:publicly_available].to_s.match(/^true$/i)
      @providers = filter_by(@providers, indexes)
      @providers = @providers.nearby(nearby_coordinate, nearby_radius) if nearby_coordinate && nearby_radius
      @providers
    end

    def indexes
      [:company_id, :user_id]
    end

    private

    def associate_with_categories
      yield
      @provider.categories = Category.where(id: params[:category_ids], company_id: @provider.company_id)
    end

    def associate_with_company
      yield
      @provider.company.providers << @provider if @provider.persisted?
    end

    def associate_with_public
      yield
      @provider.update_attribute(:publicly_available, true)
    end

    def invite_user?
      user = params[:user_id] ? User.find(params[:user_id]) : nil
      return false if user
      user = User.where(email: params[:contact][:email]).first if params[:contact] && params[:contact][:email]
      user.nil?
    end

    def nearby_coordinate
      @nearby_coordinate ||= begin
        latlng = params[:nearby].to_s.split(/,/).map(&:strip)
        Coordinate.new(latlng[0], latlng[1]) rescue nil if latlng.try(:size) == 2
      end
      @nearby_coordinate
    end

    def nearby_radius
      params[:radius].try(:to_f) || 10.to_f  # TODO: make default radius in miles configurable
    end

    def send_invitation
      yield
      send_invites = @provider.user && @provider.persisted?
      @provider.user.invitations.create(sender: current_user) if send_invites
      @provider.user.invitations.create(type: :pin, sender: current_user) if send_invites && @provider.contact && @provider.contact.mobile
    end

    def provider_params
      params[:contact_attributes] = params.delete(:contact) if params.key? :contact
      params[:contact_attributes][:time_zone_id] ||= Company.find(params[:company_id]).contact.time_zone_id rescue nil if params[:contact_attributes] && !params[:contact_attributes].key?(:time_zone_id)
      params.permit(
        :company_id, { contact_attributes: permitted_contact_params }, :permissions, :user_id, :available
      )
    end
  end
end
