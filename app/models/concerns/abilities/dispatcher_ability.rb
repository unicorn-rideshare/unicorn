module DispatcherAbility
  extend ActiveSupport::Concern

  included do
    def dispatcher_abilities
      can :read, Attachment, attachable_type: WorkOrder.name, attachable_id: dispatcher_accessible_company_work_order_ids if fetching_resource_index? && [Attachment, Comment].include?(resource)

      can :crud, Attachment do |attachment|
        authorized = attachment.user_id == authenticable.id
        case attachment.attachable_type.underscore.to_sym
          when :work_order
            authorized = dispatcher_accessible_company_work_order_ids.include?(attachment.attachable_id)
          when :user
            authorized = attachment.attachable_id == authenticable.id
        end unless authorized
        authorized
      end unless fetching_resource_index?

      can :read, Checkin, locatable_type: User.name, locatable_id: dispatcher_accessible_company_provider_user_ids if resource == Checkin

      can :read, Comment, commentable_type: Customer.name, commentable_id: dispatcher_accessible_company_customer_ids if fetching_resource_index? && [Comment, Customer].include?(resource)
      can :read, Comment, commentable_type: WorkOrder.name, commentable_id: dispatcher_accessible_company_work_order_ids if fetching_resource_index? && [Comment, WorkOrder].include?(resource)
      can [:create, :read, :update], Comment do |comment|
        authorized = comment.user_id == authenticable.id
        case comment.commentable_type.underscore.to_sym
          when :attachment
            attachment = comment.commentable
            case attachment.attachable_type.underscore.to_sym
              when :work_order
                authorized = dispatcher_accessible_company_work_order_ids.include?(attachment.attachable_id)
            end unless authorized
          when :customer
            authorized = dispatcher_accessible_company_customer_ids.include?(comment.commentable_id)
          when :work_order
            authorized = dispatcher_accessible_company_work_order_ids.include?(comment.commentable_id)
        end unless authorized
        authorized = is_create? ? authorized && comment.user_id == authenticable.id : authorized
        authorized
      end unless fetching_resource_index?
      can :destroy, Comment, user_id: authenticable.id unless fetching_resource_index?

      can :read, Company, id: dispatcher_company_ids if resource == Company

      can(:read, Contact, contactable_type: Company.name, contactable_id: dispatcher_company_ids) if resource == Contact
      can(:read, Contact, contactable_type: Customer.name, contactable_id: dispatcher_accessible_company_customer_ids) if resource == Contact
      can(:read, Contact, contactable_type: Dispatcher.name, contactable_id: dispatcher_accessible_company_dispatcher_ids) if resource == Contact
      can(:update, Contact, contactable_type: Dispatcher.name, contactable_id: user_dispatcher_ids) if resource == Contact
      can([:create, :read], Contact, contactable_type: Provider.name, contactable_id: dispatcher_accessible_company_provider_ids) if resource == Contact

      can :read, Customer, company_id: dispatcher_company_ids if [Comment, Contact, Customer].include?(resource)

      can :read, Dispatcher, company_id: dispatcher_company_ids if [Contact, Dispatcher].include?(resource)

      can :crud, DispatcherOriginAssignment, origin: { market: { company_id: dispatcher_company_ids } } if resource == DispatcherOriginAssignment

      can :read, Market, company_id: dispatcher_company_ids if resource == Market

      can :read, Origin, market: { company_id: dispatcher_company_ids } if [Contact, Origin].include?(resource)

      can :crud, Product, company_id: dispatcher_company_ids if resource == Product

      can :crud, Provider, company_id: dispatcher_company_ids if [Contact, Provider].include?(resource)
      cannot [:create, :update], Provider, company_id: nil if [Contact, Provider].include?(resource)

      can :crud, ProviderOriginAssignment, origin: { market: { company_id: dispatcher_company_ids } } if resource == ProviderOriginAssignment

      can :create, Route, company_id: dispatcher_company_ids if [Route, RouteLeg].include?(resource)
      can [:read, :update], Route, id: dispatcher_accessible_route_ids if [Route, RouteLeg].include?(resource)

      can [:read, :update], RouteLeg, route_id: dispatcher_accessible_route_ids if [Route, RouteLeg].include?(resource)

      can :create, WorkOrder, company_id: dispatcher_company_ids if [Attachment, Comment, WorkOrder].include?(resource)
      can [:read, :update], WorkOrder, id: dispatcher_accessible_company_work_order_ids if [Attachment, Comment, WorkOrder].include?(resource)
      cannot :create, WorkOrder, company_id: nil if [Attachment, Comment, WorkOrder].include?(resource)
    end

    def user_dispatchers
      @user_dispatchers ||= authenticable.dispatchers
    end

    def user_dispatcher_ids
      @user_dispatcher_ids ||= authenticable.dispatcher_ids
    end

    def dispatcher_companies
      @dispatcher_companies ||= company ? [company] : Company.with_role(:dispatcher, authenticable)
    end

    def dispatcher_company_ids
      @dispatcher_company_ids ||= dispatcher_companies.map(&:id)
    end

    def dispatcher_accessible_company_dispatcher_ids
      @dispatcher_accessible_company_dispatcher_ids ||= dispatcher_companies.map(&:dispatcher_ids).flatten
    end

    def dispatcher_accessible_company_provider_ids
      @dispatcher_accessible_company_provider_ids ||= dispatcher_companies.map(&:provider_ids).flatten
    end

    def dispatcher_accessible_company_provider_user_ids
      @dispatcher_accessible_company_dispatcher_user_ids ||= dispatcher_companies.map(&:providers).flatten.map(&:user_id)
    end

    def dispatcher_accessible_company_customer_ids
      @dispatcher_accessible_company_customer_ids ||= dispatcher_companies.map(&:customer_ids).flatten
    end

    def dispatcher_accessible_route_ids
      @dispatcher_accessible_route_ids ||= user_dispatchers.map(&:routes).flatten.map(&:id)
    end

    def dispatcher_accessible_company_work_order_ids
      @dispatcher_accessible_company_work_order_ids ||= dispatcher_companies.map(&:work_order_ids).flatten
    end
  end
end
