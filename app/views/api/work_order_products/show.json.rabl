object @work_order_product => nil

attributes :id,
           :work_order_id,
           :job_product_id,
           :price,
           :quantity

node(:job_product) do |work_order_product|
  partial 'job_products/show', object: work_order_product.job_product
end
