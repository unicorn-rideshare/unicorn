module UserAbility
  extend ActiveSupport::Concern

  included do
    def user_abilities
      return unless authenticable && authenticable.is_a?(User)

      can :crud, Attachment, attachable_type: User.name, attachable_id: authenticable.id

      can :crud, Device, user_id: authenticable.id

      can :conversations, Message
      can :read, Message, recipient_id: authenticable.id
      can :crud, Message, sender_id: authenticable.id

      can :read, Notification, recipient_id: authenticable.id

      can [:create, :charge, :read, :destroy], PaymentMethod, user_id: authenticable.id

      can [:create, :destroy], Token, authenticable_type: User.name, authenticable_id: authenticable.id

      can [:read, :update], User, id: authenticable.id

      can :read, PaperTrail::Version, whodunnit: authenticable.id.to_s
    end
  end
end
