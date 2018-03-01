class Category < ActiveRecord::Base
  include Attachable

  belongs_to :company
  validates :company_id, readonly: true, on: :update

  has_and_belongs_to_many :markets
  has_and_belongs_to_many :providers

  has_many :tasks
  has_many :work_orders

  validates :name, presence: true

  scope :greedy, ->() { includes(:attachments) }

  scope :by_market, ->(market_id) {
    joins(:markets).where('markets.id = ?', market_id)
  }

  scope :nearby, ->(coordinate, radius_in_miles = 5) {
    joins(:markets).where('markets.geom IS NOT NULL AND ST_DistanceSphere(markets.geom, ST_MakePoint(?, ?)) <= ?',
          coordinate.longitude, coordinate.latitude, radius_in_miles * 1609.34).order("markets.geom <-> ST_SetSRID(ST_MakePoint(#{coordinate.longitude}, #{coordinate.latitude}), 4326)")
  }

  scope :standalone, -> {
    where('categories.company_id IS NULL')
  }

  alias :icon_image_url :profile_image_url

  def price_per_hour(market = nil)
    return 0.0  # FIXME-- this should be avg hourly rate of providers in this category, in the given market...
  end

  def price_per_mile(market = nil)
    0.50  # FIXME-- this should be calculated based on market near a given coordinate
  end
end
