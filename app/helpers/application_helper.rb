module ApplicationHelper
  def current_user
    @current_user
  end

  def current_roles
    return [] unless @current_token
    @current_token.roles
  end

  def user_signed_in?
    current_user.present?
  end
end
