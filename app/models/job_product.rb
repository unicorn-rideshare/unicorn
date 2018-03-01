class JobProduct < ActiveRecord::Base

  belongs_to :job
  validates :job, presence: true
  validates :job_id, readonly: true, on: :update
  validate :products_company_must_match

  belongs_to :product
  validates :product, presence: true
  validates :product_id, readonly: true, on: :update

  has_many :work_order_products

  before_validation :cascade_product_price, on: :create

  validate :is_unique?, on: :create

  def estimated_cost
    return nil unless price && initial_quantity && price >= 0.0 && initial_quantity >= 0.0
    (price * initial_quantity).to_f
  end

  def remaining_quantity
    initial_quantity.to_f - work_order_products.map(&:quantity).reduce(&:+).to_f
  end

  def remaining_value
    return nil unless price && remaining_quantity && price >= 0.0 && remaining_quantity >= 0.0
    (price * remaining_quantity).to_f
  end

  def revenue
    revenue_per_unit = product.data[:revenue_per_unit]
    return nil unless revenue_per_unit && initial_quantity && revenue_per_unit >= 0.0 && initial_quantity >= 0.0
    (revenue_per_unit * initial_quantity).to_f
  end

  def total_sq_ft
    return 0.0 unless product.data[:unit_of_measure].to_s.downcase.gsub(/ /, '_').to_sym == :sq_ft
    return 0.0 unless initial_quantity
    initial_quantity
  end

  private

  def cascade_product_price
    return if self.price.present?
    return unless product && product.data[:price]
    self.price = product.data[:price].to_f
  end

  def is_unique?
    return unless job_id && product_id
    is_unique = JobProduct.where(job_id: job_id, product_id: product_id).count == 0
    errors.add(:base, :must_be_unique) unless is_unique
  end

  def products_company_must_match
    return unless job_id && product_id && product.company_id
    match = job.company_id == product.company_id
    errors.add(:product_id, :product_company_must_match_job_company) unless match
  end
end
