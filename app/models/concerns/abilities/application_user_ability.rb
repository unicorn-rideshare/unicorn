module ApplicationUserAbility
  extend ActiveSupport::Concern

  included do
    def application_user_abilities
      return unless authenticable && authenticable.is_a?(User)

      can [:create, :read, :destroy], Checkin, locatable_type: User.name, locatable_id: authenticable.id

      can :read, Category, company_id: nil

      can [:create, :read, :update], Company, user_id: authenticable.id

      can [:create, :read], Market, company_id: nil

      can :read, Provider, company_id: nil
      can :read, Provider, publicly_available: true
      can :crud, Provider, company_id: nil, user_id: authenticable.id

      can [:read, :update], Task, user_id: authenticable.id

      can :create, WorkOrder, company_id: nil, customer_id: nil, user_id: authenticable.id
      can [:read, :update], WorkOrder, user_id: authenticable.id
    end
  end
end
