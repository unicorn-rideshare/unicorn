object @company => nil

attributes :id,
           :user_id,
           :name,
           :config,
           :stripe_customer_id,
           :stripe_credit_card_id

node(:contact) do |company|
  partial 'contacts/show', object: company.contact
end

node(:stripe_customer) do |company|
  company.stripe_customer
end if @include_stripe_customer
