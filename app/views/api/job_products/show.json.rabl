object @job_product => nil

attributes :id,
           :job_id,
           :product_id,
           :price,
           :estimated_cost,
           :initial_quantity,
           :remaining_quantity,
           :remaining_value

node(:product) do |job_product|
  partial 'products/show', object: job_product.product
end
