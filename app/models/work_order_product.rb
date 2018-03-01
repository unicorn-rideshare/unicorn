class WorkOrderProduct < ActiveRecord::Base

  belongs_to :work_order
  validates :work_order, presence: true
  validates :work_order_id, readonly: true, on: :update
  validate :job_products_job_must_match

  belongs_to :job_product
  validates :job_product, presence: true
  validates :job_product_id, readonly: true, on: :update

  before_validation :cascade_product_price, on: :create

  validate :is_unique?, on: :create

  def estimated_cost
    return nil unless price && quantity && price >= 0.0 && quantity >= 0.0
    (price * quantity).to_f
  end

  def product
    return nil unless job_product_id
    job_product.product
  end

  private

  def cascade_product_price
    return if self.price.present?
    self.price ||= job_product.price if job_product
    self.price ||= 0.0
    return unless product && product.data[:price]
    self.price = product.data[:price].to_f
  end

  def is_unique?
    return unless work_order_id && job_product_id
    is_unique = WorkOrderProduct.where(work_order_id: work_order_id, job_product_id: job_product_id).count == 0
    errors.add(:base, :must_be_unique) unless is_unique
  end

  def job_products_job_must_match
    return unless work_order_id && job_product_id && job_product.job_id
    match = job_product.job_id == work_order.job_id
    errors.add(:job_product_id, :job_products_job_must_match) unless match
  end
end
