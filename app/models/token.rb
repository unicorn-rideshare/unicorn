require 'bcrypt'

class Token < ActiveRecord::Base
  include BCrypt

  validates :token, presence: true

  belongs_to :authenticable, polymorphic: true
  validates :authenticable, presence: true

  validates :authenticable_id, presence: true
  validates :authenticable_id, readonly: true, on: :update

  validates :authenticable_type, presence: true
  validates :authenticable_type, readonly: true, on: :update

  before_validation :reset_token, on: :create

  around_save :schedule_expiration_job

  after_destroy :unschedule_expiration_job

  attr_reader :uuid # transient

  default_scope { where(invalidated_at: nil) }

  alias_method :invalidated?, :readonly?

  class << self
    def inheritance_column
      'subclass'
    end
  end

  def authenticate(uuid)
    BCrypt::Password.new(token_hash) == uuid
  end

  def expires?
    expires_at.present?
  end

  def expired?
    return false unless expires?
    DateTime.now > expires_at
  end

  def invalidated?
    invalidated_at.present?
  end

  def reset_token
    self.token = SecureRandom.uuid
    @uuid = Digest::MD5.hexdigest(SecureRandom.uuid)
    self.token_hash = BCrypt::Password.create(uuid)
  end

  private

  def invalidate
    update_attribute(:invalidated_at, DateTime.now)
    unschedule_expiration_job
  end

  def schedule_expiration_job
    expiration_rescheduled = expires? && self.expires_at_changed?
    new_record = new_record?
    yield
    reload if new_record
    reschedule_expiration_job = persisted? && valid? && expiration_rescheduled
    Resque.remove_delayed(TokenExpirationJob, self.id) if reschedule_expiration_job
    Resque.enqueue_at(self.expires_at, TokenExpirationJob, self.id) if reschedule_expiration_job
  end

  def unschedule_expiration_job
    Resque.remove_delayed(TokenExpirationJob, self.id) if expires?
  end
end
