module ApplicationHelper
  def angular_app_name
    uses_application_js? ? 'unicornApp' : 'authApp'  # FIXME-- make this more flexible
  end

  def angular_controller
    controller.controller_name == 'work_orders' ? 'WorkOrderCheckinCtrl' : 'ApplicationCtrl'  # FIXME-- make this more flexible
  end

  def body_class_name
    uses_application_js? ? 'no-margin-top' : 'unauthenticated-page'  # FIXME-- make this more flexible
  end

  def current_user
    @current_user
  end

  def current_roles
    return [] unless @current_token
    @current_token.roles
  end

  def flash_json
    messages = []
    messages.push(type: 'info', message: flash.notice) if flash.key?('notice')
    messages.push(type: 'warning', message: flash.alert) if flash.key?('alert')
    messages.to_json.html_safe
  end

  def menu_partial
    return :company_admin_navigation_menu if current_user.is_company_admin?
    :dispatcher_navigation_menu if current_user.is_dispatcher?
  end

  def stylesheet_name
    uses_application_js? ? 'application' : 'login'
  end

  def user_signed_in?
    current_user.present?
  end

  def uses_application_js?
    user_signed_in? || controller.controller_name == 'work_orders'
  end
end
