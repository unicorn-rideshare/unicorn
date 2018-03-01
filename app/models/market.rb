class Market < ActiveRecord::Base

  belongs_to :company
  validates :company_id, readonly: true, on: :update

  validates :name, presence: true

  has_and_belongs_to_many :categories

  has_many :origins

  after_create :associate_default_categories
  after_create :geocode, if: lambda { self.google_place_id.present? }

  default_scope { order('id') }

  scope :ordered_by_distance_from_coordinate, ->(coordinate) {
    unscope(:order).where('markets.geom IS NOT NULL').order("markets.geom <-> ST_SetSRID(ST_MakePoint(#{coordinate.longitude}, #{coordinate.latitude}), 4326)")
  }

  private

  def associate_default_categories
    return unless persisted?
    Category.standalone.each do |category|
      self.categories << category
    end
  end

  def geocode
    return unless persisted?
    GeocodeMarketJob.perform(self.id)
    self.reload
  end
end
