object @job => nil

attributes :id,
           :company_id,
           :customer_id,
           :name,
           :type,
           :status,
           :quoted_price_per_sq_ft,
           :thumbnail_image_url

node(:company) do |job|
  partial 'companies/show', object: job.company
end if @include_company

node(:customer) do |job|
  partial 'customers/show', object: job.customer
end if @include_customer

node(:contract_revenue) do |job|
  job.contract_revenue
end if @include_expenses

node(:expenses) do |job|
  partial 'expenses/index', object: job.expenses
end if @include_expenses

node(:expensed_amount) do |job|
  job.expensed_amount
end if @include_expenses

node(:expenses_count) do |job|
  job.expense_ids.size
end if @include_expenses

node(:labor_revenue) do |job|
  job.labor_revenue
end if @include_expenses

node(:labor_cost) do |job|
  job.labor_cost
end if @include_expenses

node(:labor_cost_per_sq_ft) do |job|
  job.labor_cost_per_sq_ft
end if @include_expenses

node(:labor_cost_percentage_of_revenue) do |job|
  job.labor_cost_percentage_of_revenue
end if @include_expenses

node(:materials) do |job|
  partial 'job_products/index', object: job.materials
end if @include_materials

node(:materials_revenue) do |job|
  job.materials_revenue
end if @include_expenses

node(:materials_cost) do |job|
  job.materials_cost
end if @include_expenses

node(:materials_cost_per_sq_ft) do |job|
  job.materials_cost_per_sq_ft
end if @include_expenses

node(:materials_cost_percentage_of_revenue) do |job|
  job.materials_cost_percentage_of_revenue
end if @include_expenses

node(:profit) do |job|
  job.profit
end if @include_expenses

node(:profit_margin) do |job|
  job.profit_margin
end if @include_expenses

node(:profit_per_sq_ft) do |job|
  job.profit_per_sq_ft
end if @include_expenses

node(:total_sq_ft) do |job|
  job.total_sq_ft
end if @include_expenses

node(:cost) do |job|
  job.cost
end if @include_expenses

node(:supervisors) do |job|
  partial 'providers/index', object: job.supervisors
end if @include_supervisors

node(:work_orders) do |job|
  partial 'work_orders/index', object: job.work_orders.greedy
end if @include_work_orders

node(:work_orders_count) do |job|
  job.work_order_ids.size
end
