module CompanyAbility
  extend ActiveSupport::Concern

  included do
    def company_abilities
      can :crud, Category, company_id: authenticable.id
      can [:read, :update], Company, id: authenticable.id
      can(:crud, Contact, contactable_type: Company.name, contactable_id: authenticable.id)
      can(:crud, Contact, contactable_type: Customer.name, contactable_id: authenticable.customer_ids)
      can(:crud, Contact, contactable_type: Dispatcher.name, contactable_id: authenticable.dispatcher_ids)
      can(:crud, Contact, contactable_type: Provider.name, contactable_id: authenticable.provider_ids)
      can :crud, Customer, company_id: authenticable.id
      can :crud, Dispatcher, company_id: authenticable.id
      can :crud, DispatcherOriginAssignment, origin: { market: { company_id: authenticable.id } }
      can :crud, Job, company_id: authenticable.id
      can :crud, Market, company_id: authenticable.id
      can :crud, Origin, market: { company_id: authenticable.id }
      can :crud, Product, company_id: authenticable.id
      can :crud, Provider, company_id: authenticable.id
      can :crud, ProviderOriginAssignment, origin: { market: { company_id: authenticable.id } }
      can :crud, Route, company_id: authenticable.id
      can :crud, Task, company_id: authenticable.id
      can :crud, WorkOrder, company_id: authenticable.id
    end
  end
end
