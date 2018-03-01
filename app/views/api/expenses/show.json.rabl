object @expense => nil

attributes :id,
           :user_id,
           :expensable_id,
           :amount,
           :description

node(:expensable_type) do |expense|
  expense.expensable_type.underscore
end

node(:attachments) do |expense|
  partial 'attachments/index', object: expense.attachments
end

node(:created_at) do |expense|
  expense.created_at.iso8601
end

node(:updated_at) do |expense|
  expense.updated_at.iso8601
end

node(:incurred_at) do |expense|
  expense.incurred_at ? expense.incurred_at.iso8601 : nil
end
