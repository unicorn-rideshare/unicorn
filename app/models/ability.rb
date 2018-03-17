class Ability
  include CanCan::Ability
  include AdminAbility
  include ApplicationUserAbility
  include CompanyAbility
  include CompanyAdminAbility
  include DispatcherAbility
  include ProviderAbility
  include UserAbility

  def initialize(authenticable, params = nil)
    alias_action :create, :read, :update, :destroy, to: :crud

    @authenticable = authenticable
    @params = params
    @roles = authenticable.try(:roles) if authenticable

    @company = Company.find(params[:company_id]) if params && params[:company_id]
    @company ||= resource_instance.respond_to?(:company) ? resource_instance.send(:company) : nil
    @company ||= resource_instance.respond_to?(:company_id) ? (Company.find(resource_instance.send(:company_id)) rescue nil) : nil
    @company ||= parent_resource_instance.respond_to?(:company) ? parent_resource_instance.send(:company) : nil
    @company ||= parent_resource_instance.respond_to?(:company_id) ? (Company.find(parent_resource_instance.send(:company_id)) rescue nil) : nil

    if authenticable
      user_abilities if is_user?
      admin_abilities if is_admin?
      company_abilities if is_company_api?
      company_admin_abilities if is_company_admin?
      dispatcher_abilities if is_dispatcher?
      provider_abilities if is_provider?
    else
      anonymous_abilities
    end
  end

  private

  attr_accessor :authenticable
  attr_accessor :company
  attr_accessor :params
  attr_accessor :roles

  def anonymous_abilities
    can [:create, :reset_password], User

    can :read, WorkOrder, ['id = ?', params[:id]] do |work_order|
      work_order.customer_communications_config[:exposes_status_publicly]
    end if params

    can :sms, Message
  end

  def applicable_roles
    authenticable.roles & ((company || authenticable).roles + resource_roles).uniq
  end

  def fetching_resource_index?
    params && params[:action].to_s.to_sym == :index
  end

  def is_create?
    params && params[:action].to_s.to_sym == :create
  end

  def is_update?
    params && params[:action].to_s.to_sym == :update
  end

  def is_user?
    authenticable.is_a?(User)
  end

  def is_admin?
    false
  end

  def is_company_api?
    authenticable.is_a?(Company)
  end

  def is_company_admin?
    is_user? && applicable_roles.select { |role| role.name.to_sym == :admin }.size > 0
  end

  def is_dispatcher?
    return true if authenticable.is_a?(Dispatcher)
    is_user? && applicable_roles.select { |role| role.name.to_sym == :dispatcher }.size > 0
  end

  def is_provider?
    return true if authenticable.is_a?(Provider)
    is_user? && applicable_roles.select { |role| role.name.to_sym == :provider }.size > 0
  end

  def parent_resource
    params.each do |key, value|
      match = key.match(/^(.*)_id$/i)
      return key.gsub(/^(.*)_id$/i, '\1').classify.constantize rescue nil if match
    end
    nil
  end

  def parent_resource_id
    params["#{parent_resource.to_s.downcase}_id".to_sym]
  end

  def parent_resource_instance
    @parent_resource_instance ||= parent_resource.find(parent_resource_id) rescue nil
  end

  def resource
    match = params[:controller].to_s.match(/\/(.*)$/i)
    match = match[match.size - 1] if match
    match.classify.constantize rescue nil if match
  end

  def resource_id
    params["#{resource.to_s.downcase}_id".to_sym] || params[:id]
  end

  def resource_instance
    @resource_instance ||= resource.find(resource_id) rescue nil
  end

  def resource_roles
    roles = []
    roles += resource_instance && resource_instance.respond_to?(:roles) ? resource_instance.roles : []
    roles += parent_resource_instance && parent_resource_instance.respond_to?(:roles) ? parent_resource_instance.roles : []
    roles
  end
end
