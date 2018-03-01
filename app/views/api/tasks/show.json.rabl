object @task => nil

attributes :id,
           :company_id,
           :task_id,
           :category_id,
           :user_id,
           :provider_id,
           :job_id,
           :work_order_id,
           :name,
           :description,
           :status

node(:due_at) do |task|
  task.due_at ? task.due_at.iso8601 : nil
end

node(:canceled_at) do |task|
  task.canceled_at ? task.canceled_at.iso8601 : nil
end

node(:completed_at) do |task|
  task.completed_at ? task.completed_at.iso8601 : nil
end

node(:declined_at) do |task|
  task.declined_at ? task.declined_at.iso8601 : nil
end
