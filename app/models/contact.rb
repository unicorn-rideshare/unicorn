class Contact < ActiveRecord::Base
  include Geocodable

  validates :name, presence: true

  belongs_to :contactable, polymorphic: true
  validates :contactable_id, uniqueness: { scope: :contactable_type }, allow_nil: true
  validates :contactable_id, readonly: true, on: :update
  validates :contactable_type, readonly: true, on: :update

  validate :validate_time_zone, if: lambda { self.require_time_zone? }

  def first_name
    name.split(/ /)[0].strip
  end

  def last_name
    name_parts = name.split(/ /)
    return nil if name_parts.size < 2
    name_parts.last.strip
  end

  def require_time_zone?
    return contactable.require_contact_time_zone? if contactable.respond_to?(:require_contact_time_zone?)
    false
  end

  def time_zone
    TimeZone.find(time_zone_id) if time_zone_id
  end

  def time_zone=(value)
    self.time_zone_id = value.try(:name)
  end

  def coordinate
    return nil if latitude.nil? || longitude.nil?
    Coordinate.new(latitude, longitude)
  end

  def validate_time_zone
    return unless require_time_zone?
    errors.add(:time_zone_id, :contact_timezone_required) unless time_zone_id
    errors.add(:time_zone, :contact_timezone_required) unless time_zone
  end
end
