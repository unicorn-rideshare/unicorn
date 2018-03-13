module ProviderAbility
  extend ActiveSupport::Concern

  included do
    def provider_abilities
      can :read, Attachment, attachable_type: Comment.name, attachable_id: provider_accessible_company_work_order_ids if fetching_resource_index? && [Attachment].include?(resource) && [WorkOrder].include?(parent_resource)
      can :read, Attachment, attachable_type: WorkOrder.name, attachable_id: provider_accessible_company_work_order_ids if fetching_resource_index? && [Attachment].include?(resource) && [WorkOrder].include?(parent_resource)
      can :read, Attachment, attachable_type: Job.name, attachable_id: provider_accessible_company_job_ids if fetching_resource_index? && [Attachment].include?(resource) && [Job].include?(parent_resource)
      can :read, Attachment, attachable_type: nil, attachable_id: nil if fetching_resource_index? && [Attachment].include?(resource) && [Job].include?(parent_resource)

      can [:create, :read, :update], Attachment do |attachment|
        authorized = attachment.user_id == authenticable.id
        case attachment.attachable_type.underscore.to_sym
          when :comment
            comment = attachment.attachable
            case comment.commentable_type.underscore.to_sym
              when :work_order
                authorized = provider_accessible_company_work_order_ids.include?(comment.commentable_id)
            end unless authorized
          when :expense
            authorized = (provider_accessible_company_job_ids + provider_accessible_company_work_order_ids).include?(attachment.attachable.expensable_id)
          when :job
            authorized = provider_accessible_company_job_ids.include?(attachment.attachable_id)
            if authorized && is_update?
              is_supervisor = authenticable.providers.select { |provider| attachment.attachable.is_supervisor?(provider) }.size > 0
              authorized = is_supervisor || attachment.user_id == authenticable.id
            end
          when :work_order
            authorized = provider_accessible_company_work_order_ids.include?(attachment.attachable_id)
          when :user
            authorized = attachment.attachable_id == authenticable.id
        end unless authorized
        authorized
      end unless fetching_resource_index?

      can :read, Category, id: provider_accessible_company_category_ids if [Attachment, Category].include?(resource)

      can :read, Checkin, locatable_type: User.name, locatable_id: provider_accessible_company_provider_user_ids if resource == Checkin

      can :read, Comment, commentable_type: Customer.name, commentable_id: provider_accessible_company_customer_ids if fetching_resource_index? && [Comment, Customer].include?(resource)
      can :read, Comment, commentable_type: WorkOrder.name, commentable_id: provider_accessible_company_work_order_ids if fetching_resource_index? && [Comment, WorkOrder].include?(resource)
      can :read, Comment, commentable_type: Job.name, commentable_id: provider_accessible_company_job_ids if fetching_resource_index? && [Comment, Job].include?(resource)
      can [:create, :read, :update], Comment do |comment|
        authorized = comment.user_id == authenticable.id
        case comment.commentable_type.underscore.to_sym
          when :attachment
            attachment = comment.commentable
            case attachment.attachable_type.underscore.to_sym
              when :work_order
                authorized = provider_accessible_company_work_order_ids.include?(attachment.attachable_id)
            end unless authorized
          when :customer
            authorized = provider_accessible_company_customer_ids.include?(comment.commentable_id)
          when :job
            authorized = provider_accessible_company_job_ids.include?(comment.commentable_id) && !is_create? && !is_update?
          when :work_order
            authorized = provider_accessible_company_work_order_ids.include?(comment.commentable_id)
        end unless authorized
        authorized
      end unless fetching_resource_index?
      can :destroy, Comment, user_id: authenticable.id unless fetching_resource_index?

      can :read, Company, id: provider_company_ids if resource == Company

      can(:read, Contact, contactable_type: Company.name, contactable_id: provider_company_ids) if resource == Contact
      can(:read, Contact, contactable_type: Customer.name, contactable_id: provider_accessible_company_customer_ids) if resource == Contact
      can(:read, Contact, contactable_type: Dispatcher.name, contactable_id: provider_accessible_company_dispatcher_ids) if resource == Contact
      can(:read, Contact, contactable_type: Provider.name, contactable_id: provider_accessible_company_provider_ids) if resource == Contact
      can(:update, Contact, contactable_type: Provider.name, contactable_id: user_provider_ids) if resource == Contact

      can :read, Customer, company_id: provider_company_ids if [Comment, Contact, Customer].include?(resource)

      can :read, Dispatcher, id: provider_accessible_company_dispatcher_ids if [Contact, Dispatcher].include?(resource)

      can :read, Expense, expensable_type: Job.name, expensable_id: provider_accessible_company_job_ids if fetching_resource_index? && [Attachment, Expense, Job].include?(resource)
      can [:create, :read, :update], Expense, expensable_type: WorkOrder.name, expensable_id: provider_accessible_company_work_order_ids if fetching_resource_index? && [Attachment, Expense, WorkOrder].include?(resource)

      can [:create, :read, :update], Expense do |expense|
        authorized = false
        case expense.expensable_type.underscore.to_sym
          when :job
            authorized = provider_supervisor_company_job_ids.include?(expense.expensable_id)
            authorized = authenticable.providers.select { |provider| expense.expensable.is_supervisor?(provider) }.size > 0 if authorized && is_update?
          when :work_order
            authorized = provider_accessible_company_work_order_ids.include?(expense.expensable_id)
        end
        authorized
      end unless fetching_resource_index?

      can :read, Product, company_id: provider_company_ids if resource == Product
      can [:create, :update], Product do |product|
        authorized = false
        if product.company_id
          supervising_company_ids = Job.with_role(:supervisor, authenticable).pluck(:company_id).uniq
          authorized = supervising_company_ids.include?(product.company_id)
        end
        authorized
      end if resource == Product

      can :read, Provider, publicly_available: true if [Contact, Provider].include?(resource)
      can :read, Provider, id: user_provider_ids + provider_accessible_company_provider_ids if [Contact, Provider].include?(resource)
      can :update, Provider, id: user_provider_ids if resource == Provider
      can [:create, :update], Provider do |provider|
        authorized = false
        if provider.company_id
          supervising_company_ids = Job.with_role(:supervisor, authenticable).pluck(:company_id).uniq
          authorized = supervising_company_ids.include?(provider.company_id)
        end
        authorized
      end  if [Contact, Provider].include?(resource)
      cannot :create, Provider, company_id: nil if [Contact, Provider].include?(resource)

      can [:read, :update], Route, id: provider_accessible_route_ids if [Route, RouteLeg].include?(resource)

      can [:read, :update], RouteLeg, route_id: provider_accessible_route_ids if [Route, RouteLeg].include?(resource)

      can [:read, :update], WorkOrder, id: provider_accessible_company_work_order_ids if [Attachment, Comment, Expense, WorkOrder].include?(resource)
      can [:create, :read, :update], WorkOrder, job_id: provider_supervisor_company_job_ids if [Attachment, Comment, Expense, WorkOrder].include?(resource)
      cannot :create, WorkOrder, company_id: nil if [Attachment, Comment, Expense, WorkOrder].include?(resource)

      can [:read, :update], Job, id: (provider_supervisor_company_job_ids + provider_accessible_company_job_ids).uniq if [Attachment, Comment, Expense, Job].include?(resource)

      can [:read, :update], Task, provider_id: user_provider_ids if [Attachment, Comment, Task].include?(resource)
      can :create, Task, job_id: (provider_supervisor_company_job_ids + provider_accessible_company_job_ids).uniq if [Attachment, Comment, Task].include?(resource)
    end

    def user_providers
      return [authenticable] if authenticable.is_a?(Provider)
      @user_providers ||= authenticable.providers
    end

    def user_provider_ids
      return [authenticable.id] if authenticable.is_a?(Provider)
      @user_provider_ids ||= authenticable.try(:provider_ids) || []
    end

    def provider_companies
      return (authenticable.company_id ? [authenticable.company] : []) if authenticable.is_a?(Provider)
      @provider_companies ||= company ? [company] : Company.with_role(:provider, authenticable)
    end

    def provider_company_ids
      return (authenticable.company_id ? [authenticable.company_id] : []) if authenticable.is_a?(Provider)
      @provider_company_ids ||= provider_companies.map(&:id)
    end

    def provider_accessible_company_category_ids
      @provider_accessible_company_category_ids ||= user_providers.map(&:categories).flatten.map(&:id)
    end

    def provider_accessible_company_dispatcher_ids
      @provider_accessible_company_dispatcher_ids ||= ProviderOriginAssignment.with_role(:provider, authenticable).map(&:origin).map(&:dispatcher_ids).flatten
    end

    def provider_accessible_company_provider_ids
      @provider_accessible_company_provider_ids ||= provider_companies.map(&:provider_ids).flatten
    end

    def provider_accessible_company_provider_user_ids
      @provider_accessible_company_provider_user_ids ||= provider_companies.map(&:providers).flatten.map(&:user_id)
    end

    def provider_accessible_company_customer_ids
      @provider_accessible_company_customer_ids ||= provider_companies.map(&:customer_ids).flatten
    end

    def provider_accessible_route_ids
      @provider_accessible_route_ids ||= Route.with_role(:provider, authenticable).pluck(:id)
    end

    def provider_job_supervisor_company_ids
      @provider_job_supervisor_company_ids ||= Job.with_role(:supervisor, authenticable).pluck(:company_id)
    end

    def provider_supervisor_company_job_ids
      @provider_supervisor_company_job_ids ||= Job.with_role(:supervisor, authenticable).pluck(:id)
    end

    def provider_accessible_company_job_ids
      @provider_accessible_company_job_ids ||= (provider_supervisor_company_job_ids + Job.with_role(:provider, authenticable).pluck(:id)).uniq
    end

    def provider_accessible_company_work_order_ids
      @provider_accessible_company_work_order_ids ||= WorkOrder.with_role(:supervisor, authenticable).pluck(:id) + WorkOrder.with_role(:provider, authenticable).pluck(:id) + WorkOrder.where(job_id: provider_accessible_company_job_ids).pluck(:id)
    end
  end
end
