object @work_order => nil

attributes :id,
           :category_id,
           :company_id,
           :customer_id,
           :job_id,
           :user_id,
           :description,
           :duration,
           :status,
           :priority,
           :provider_rating,
           :customer_rating,
           :user_rating,
           :config,
           :price

node(:estimated_distance) do |work_order|
  work_order.estimated_distance ? work_order.estimated_distance.round(1) : nil
end

node(:estimated_duration) do |work_order|
  work_order.estimated_duration ? work_order.estimated_duration.ceil : nil
end

node(:estimated_price) do |work_order|
  work_order.estimated_price ? work_order.estimated_price.round(2) : nil
end

node(:job) do |work_order|
  partial 'jobs/show', object: work_order.job
end if (locals[:object] || @work_order).job_id && !@include_work_orders

node(:category) do |work_order|
  partial 'categories/show', object: work_order.category
end

node(:customer) do |work_order|
  partial 'customers/show', object: work_order.customer
end

node(:user) do |work_order|
  partial 'users/show', object: work_order.user
end

node(:due_at) do |work_order|
  work_order.due_at ? work_order.due_at.iso8601 : nil
end

node(:estimated_cost) do |work_order|
  work_order.estimated_cost
end if @include_estimated_cost

node(:expensed_amount) do |work_order|
  work_order.expensed_amount
end if @include_expenses

node(:expenses_count) do |work_order|
  work_order.expense_ids.size
end if @include_expenses

node(:expenses) do |work_order|
  partial 'expenses/index', object: work_order.expenses
end if @include_expenses

node(:job) do |work_order|
  partial 'jobs/show', object: work_order.job
end if (locals[:object] || @work_order).job_id && (@include_job || @include_jobs)

node(:items_delivered) do |work_order|
  partial 'products/index', object: work_order.items_delivered.greedy
end if (locals[:include_products] || @include_products) || @api.nil?

node(:items_ordered) do |work_order|
  partial 'products/index', object: work_order.items_ordered.greedy
end if (locals[:include_products] || @include_products) || @api.nil?

node(:items_rejected) do |work_order|
  partial 'products/index', object: work_order.items_rejected.greedy
end if (locals[:include_products] || @include_products) || @api.nil?

node(:materials) do |work_order|
  partial 'work_order_products/index', object: work_order.materials
end if (locals[:include_products] || @include_products || @include_materials) || @api.nil?

node(:supervisors) do |work_order|
  partial 'users/index', object: work_order.supervisors
end if (locals[:include_supervisors] || @include_supervisors)

node(:scheduled_start_at) do |work_order|
  work_order.scheduled_start_at ? work_order.scheduled_start_at.iso8601 : nil
end

node(:scheduled_end_at) do |work_order|
  work_order.scheduled_end_at ? work_order.scheduled_end_at.iso8601 : nil
end

node(:started_at) do |work_order|
  work_order.started_at ? work_order.started_at.iso8601 : nil
end

node(:arrived_at) do |work_order|
  work_order.arrived_at ? work_order.arrived_at.iso8601 : nil
end

node(:ended_at) do |work_order|
  work_order.ended_at ? work_order.ended_at.iso8601 : nil
end

node(:abandoned_at) do |work_order|
  work_order.abandoned_at ? work_order.abandoned_at.iso8601 : nil
end

node(:canceled_at) do |work_order|
  work_order.canceled_at ? work_order.canceled_at.iso8601 : nil
end

node(:submitted_for_approval_at) do |work_order|
  work_order.submitted_for_approval_at ? work_order.submitted_for_approval_at.iso8601 : nil
end

node(:approved_at) do |work_order|
  work_order.approved_at ? work_order.approved_at.iso8601 : nil
end

node(:rejected_at) do |work_order|
  work_order.rejected_at ? work_order.rejected_at.iso8601 : nil
end

node(:work_order_providers) do |work_order|
  partial 'work_order_providers/index', object: work_order.work_order_providers
end if (locals[:include_work_order_providers] || @include_work_order_providers) || @api.nil?
