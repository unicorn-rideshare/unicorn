module CompanyAdminAbility
  extend ActiveSupport::Concern

  included do
    def company_admin_abilities
      can :read, Attachment, attachable_type: Comment.name, attachable_id: admin_accessible_company_work_order_ids if fetching_resource_index? && [Attachment].include?(resource) && [WorkOrder].include?(parent_resource)
      can :read, Attachment, attachable_type: WorkOrder.name, attachable_id: admin_accessible_company_work_order_ids if fetching_resource_index? && [Attachment].include?(resource) && [WorkOrder].include?(parent_resource)
      can :read, Attachment, attachable_type: Job.name, attachable_id: admin_accessible_company_job_ids if fetching_resource_index? && [Attachment].include?(resource) && [Job].include?(parent_resource)
      can :read, Attachment, attachable_type: nil, attachable_id: nil if fetching_resource_index? && [Attachment].include?(resource) && [Job].include?(parent_resource)

      can :crud, Attachment do |attachment|
        authorized = attachment.user_id == authenticable.id
        case attachment.attachable_type.underscore.downcase.to_sym
          when :comment
            comment = attachment.attachable
            case comment.commentable_type.underscore.to_sym
              when :work_order
                authorized = admin_accessible_company_work_order_ids.include?(attachment.attachable_id)
            end unless authorized
          when :expense
            authorized = admin_accessible_company_job_ids.include?(attachment.attachable.expensable_id)
          when :job
            authorized = admin_accessible_company_job_ids.include?(attachment.attachable_id)
          when :work_order
            authorized = admin_accessible_company_work_order_ids.include?(attachment.attachable_id)
          when :user
            authorized = attachment.attachable_id == authenticable.id
        end unless authorized
        authorized
      end unless fetching_resource_index?

      can :crud, Category, company_id: admin_company_ids if [Attachment, Category].include?(resource)

      can :read, Checkin, locatable_type: User.name, locatable_id: admin_accessible_company_provider_user_ids if resource == Checkin

      can :read, Comment, commentable_type: Customer.name, commentable_id: admin_accessible_company_customer_ids if fetching_resource_index? && [Comment, Customer].include?(resource)
      can :read, Comment, commentable_type: WorkOrder.name, commentable_id: admin_accessible_company_work_order_ids if fetching_resource_index? && [Comment, WorkOrder].include?(resource)
      can :read, Comment, commentable_type: Job.name, commentable_id: admin_accessible_company_job_ids if fetching_resource_index? && [Comment, Job].include?(resource)
      can :crud, Comment do |comment|
        authorized = comment.user_id == authenticable.id
        case comment.commentable_type.underscore.to_sym
          when :attachment
            attachment = comment.commentable
            case attachment.attachable_type.underscore.to_sym
              when :work_order
                authorized = admin_accessible_company_work_order_ids.include?(attachment.attachable_id)
            end unless authorized
          when :customer
            authorized = admin_accessible_company_customer_ids.include?(comment.commentable_id)
          when :job
            authorized = admin_accessible_company_job_ids.include?(comment.commentable_id) && !is_create? && !is_update?
          when :work_order
            authorized = admin_accessible_company_work_order_ids.include?(comment.commentable_id)
        end unless authorized
        authorized
      end unless fetching_resource_index?

      can [:read, :update], Company, id: admin_company_ids if resource == Company

      can(:crud, Contact, contactable_type: Company.name, contactable_id: admin_company_ids) if resource == Contact
      can(:crud, Contact, contactable_type: Customer.name, contactable_id: admin_accessible_company_customer_ids) if resource == Contact
      can(:crud, Contact, contactable_type: Dispatcher.name, contactable_id: admin_accessible_company_dispatcher_ids) if resource == Contact
      can(:crud, Contact, contactable_type: Provider.name, contactable_id: admin_accessible_company_provider_ids) if resource == Contact

      can :crud, Customer, company_id: admin_company_ids if [Comment, Contact, Customer].include?(resource)

      can :crud, Dispatcher, company_id: admin_company_ids if [Contact, Dispatcher].include?(resource)

      can :crud, DispatcherOriginAssignment, origin: { market: { company_id: admin_company_ids } } if resource == DispatcherOriginAssignment

      can :read, Expense, expensable_type: Job.name, expensable_id: admin_accessible_company_job_ids if fetching_resource_index? && [Attachment, Expense, Job].include?(resource)
      can :read, Expense, expensable_type: WorkOrder.name, expensable_id: admin_accessible_company_work_order_ids if fetching_resource_index? && [Attachment, Expense, WorkOrder].include?(resource)

      can :crud, Expense do |expense|
        authorized = expense.user_id == authenticable.id
        case expense.expensable_type.underscore.downcase.to_sym
          when :job
            authorized = admin_accessible_company_job_ids.include?(expense.expensable_id)
          when :work_order
            authorized = admin_accessible_company_work_order_ids.include?(expense.expensable_id)
        end unless authorized
        authorized
      end unless fetching_resource_index?

      can :crud, Product, company_id: admin_company_ids if resource == Product

      can :crud, Market, company_id: admin_company_ids if resource == Market

      can :crud, Origin, market: { company_id: admin_company_ids } if [Contact, Origin].include?(resource)

      can :read, Provider, company_id: nil if [Contact, Provider].include?(resource)
      can :crud, Provider, company_id: admin_company_ids if [Contact, Provider].include?(resource)
      cannot :create, Provider, company_id: nil if [Contact, Provider].include?(resource)

      can :crud, ProviderOriginAssignment, origin: { market: { company_id: admin_company_ids } } if resource == ProviderOriginAssignment

      can :crud, Route, company_id: admin_company_ids if [Route, RouteLeg].include?(resource)
      can :crud, RouteLeg, route_id: admin_accessible_company_route_ids if [Route, RouteLeg].include?(resource)

      can :crud, WorkOrder, company_id: nil, customer_id: admin_accessible_company_customer_ids if [Attachment, Comment, Expense, WorkOrder].include?(resource)
      can :crud, WorkOrder, company_id: admin_company_ids if [Attachment, Comment, Expense, WorkOrder].include?(resource)
      cannot :create, WorkOrder, company_id: nil if [Attachment, Comment, Expense, WorkOrder].include?(resource)

      can :crud, Job, company_id: admin_company_ids if [Attachment, Comment, Expense, Job].include?(resource)

      can :crud, Task, company_id: admin_company_ids if [Attachment, Comment, Task].include?(resource)
    end

    def admin_companies
      @admin_companies ||= company ? [company] : Company.with_role(:admin, authenticable)
    end

    def admin_company_ids
      @admin_company_ids ||= admin_companies.map(&:id)
    end

    def admin_accessible_company_customer_ids
      @admin_accessible_company_customer_ids ||= admin_companies.map(&:customer_ids).flatten
    end

    def admin_accessible_company_dispatcher_ids
      @admin_accessible_company_dispatcher_ids ||= admin_companies.map(&:dispatcher_ids).flatten
    end

    def admin_accessible_company_provider_ids
      @admin_accessible_company_provider_ids ||= admin_companies.map(&:provider_ids).flatten
    end

    def admin_accessible_company_provider_user_ids
      @admin_accessible_company_provider_user_ids ||= admin_companies.map(&:providers).flatten.map(&:user_id)
    end

    def admin_accessible_company_route_ids
      @admin_accessible_company_route_ids ||= admin_companies.map(&:routes).flatten.map(&:id)
    end

    def admin_accessible_company_job_ids
      @admin_accessible_company_job_ids ||= admin_companies.map(&:job_ids).flatten
    end

    def admin_accessible_company_work_order_ids
      @admin_accessible_company_work_order_ids ||= admin_companies.map(&:work_order_ids).flatten
    end
  end
end
