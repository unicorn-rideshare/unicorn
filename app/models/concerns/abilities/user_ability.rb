module UserAbility
  extend ActiveSupport::Concern

  included do
    def user_abilities
      return unless authenticable && authenticable.is_a?(User)

      can :crud, Attachment, attachable_type: User.name, attachable_id: authenticable.id

      can [:create, :read, :destroy], Checkin, locatable_type: User.name, locatable_id: authenticable.id

      can :read, Category, company_id: nil

      can [:create, :read, :update], Company, user_id: authenticable.id

      can :crud, Device, user_id: authenticable.id

      can [:create, :read], Market, company_id: nil

      can :conversations, Message
      can :read, Message, recipient_id: authenticable.id
      can :crud, Message, sender_id: authenticable.id

      can :read, Notification, recipient_id: authenticable.id

      can [:create, :charge, :read, :destroy], PaymentMethod, user_id: authenticable.id

      can :read, Provider, company_id: nil
      can :crud, Provider, user_id: authenticable.id

      can [:read, :update], Task, user_id: authenticable.id

      can [:create, :destroy], Token, authenticable_type: User.name, authenticable_id: authenticable.id

      can [:read, :update], User, id: authenticable.id

      can :create, WorkOrder, company_id: nil, customer_id: nil, user_id: authenticable.id
      can [:read, :update], WorkOrder, user_id: authenticable.id
    end
  end
end
