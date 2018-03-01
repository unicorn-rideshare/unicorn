class Checkin < ActiveRecord::Base

  belongs_to :locatable, polymorphic: true
  validates :locatable_id, readonly: true, on: :update
  validates :locatable_type, readonly: true, on: :update

  validates :checkin_at, presence: true
  validates :geom, presence: true

  validates :latitude, numericality:
    { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }

  validates :longitude, numericality:
    { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }

  before_validation :update_geometry, on: :create

  default_scope { order('checkin_at DESC') }

  scope :ordered_by_checkin_at_asc, -> {
    unscope(:order).order('checkin_at ASC')
  }

  scope :starting_at, ->(starting_at = DateTime.now) {
    where('checkin_at >= :starting_at', starting_at: starting_at)
  }

  scope :ending_at, ->(ending_at = DateTime.now) {
    where('checkin_at <= :ending_at', ending_at: ending_at)
  }

  after_create :dispatch_notifications

  def coordinate
    Coordinate.new(latitude, longitude)
  end

  def latitude
    self[:latitude].to_f
  end

  def longitude
    self[:longitude].to_f
  end

  def heading
    self[:heading].to_f
  end

  private

  def denormalize_provider_location  # HACK!!! this needs to get factored out of checkin model
    if locatable.is_a?(User)
      locatable.last_checkin_geom = self.geom
      locatable.last_checkin_latitude = self.latitude
      locatable.last_checkin_longitude = self.longitude
      locatable.last_checkin_heading = self.heading
      locatable.last_checkin_at = self.checkin_at
      locatable.save!

      locatable.work_orders.user_location_subscriber.each do |wo|
        wo.update_user_location(self)
      end
    end

    if locatable.respond_to?(:providers)
      locatable.providers.each do |provider|
        provider.last_checkin_geom = self.geom
        provider.last_checkin_latitude = self.latitude
        provider.last_checkin_longitude = self.longitude
        provider.last_checkin_heading = self.heading
        provider.last_checkin_at = self.checkin_at
        provider.save!

        Resque.enqueue(ProviderLocationChangedJob, provider.id) if provider.available
      end
    end
  end

  def dispatch_notifications
    denormalize_provider_location # HACK!!!! get rid of this

    payload = Rabl::Renderer.new('checkins/show',
                                 self,
                                 view_path: 'app/views',
                                 format: 'hash').render

    WebsocketRails["#{locatable_type.downcase}_checkins_#{locatable_id}"].trigger(:new, payload)
  end

  def update_geometry
    result = self.class.connection.execute("SELECT ST_SetSRID(ST_MakePoint(#{longitude}, #{latitude}), 4326) as geom").first
    self.geom = result ? result['geom'] : nil
  end
end
