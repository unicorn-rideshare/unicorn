class Product < ActiveRecord::Base
  include Attachable

  belongs_to :company
  validates :company, presence: true
  validates :company_id, readonly: true, on: :update

  belongs_to :product
  validates :product_id, readonly: true, on: :update
  validate :subproduct_must_belong_to_product_company

  has_many :variants, class_name: Product.name, inverse_of: :product

  has_and_belongs_to_many :deliveries, class_name: WorkOrder.name, join_table: :delivered_products_work_orders
  has_and_belongs_to_many :orders, class_name: WorkOrder.name, join_table: :ordered_products_work_orders
  has_and_belongs_to_many :rejections, class_name: WorkOrder.name, join_table: :rejected_products_work_orders

  has_many :jobs, through: :job_products
  has_many :job_products, inverse_of: :product

  before_save :populate_barcode_image, if: :gtin_changed?

  default_scope { order('gtin') }

  scope :query, ->(query) {
    where('gtin LIKE ?', "#{query}%")
  }

  scope :greedy, ->() {
    includes(:attachments, :variants)
  }

  scope :top_level, ->() {
    where('products.product_id IS NULL')
  }

  alias :image_url :profile_image_url

  def barcode_png
    Barby::EAN13.new(gtin[0..11]).to_png rescue Barby::Code39.new(gtin).to_png rescue nil
  end

  def data
    super.with_indifferent_access
  end

  private

  def populate_barcode_image
    self.barcode_uri = "data:image/png;base64,#{Base64.encode64(barcode_png).gsub(/\n/, '')}" if barcode_png
  end

  def subproduct_must_belong_to_product_company
    return unless self.product_id
    match = self.company_id == self.product.company_id
    errors.add(:base, :product_company_must_match_subproduct_company) unless match
  end
end
