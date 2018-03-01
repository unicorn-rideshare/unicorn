class Invitation < ActiveRecord::Base

  attr_accessor :type

  belongs_to :invitable, polymorphic: true
  validates :invitable_id, readonly: true, on: :update
  validates :invitable_type, readonly: true, on: :update

  belongs_to :sender, class_name: User.name
  validates :sender_id, readonly: true, on: :update

  validates_uniqueness_of :token

  before_validation :reset_token, on: :create

  around_save :schedule_expiration_job

  around_destroy :unschedule_expiration_job

  default_scope { where('accepted_at IS NULL AND (expires_at IS NULL OR expires_at >= :date)', date: DateTime.now).order('created_at asc') }

  def accept
    can_accept = !accepted? && !expired?
    errors.add(:base, 'expired invitation cannot be accepted') if !can_accept && expired?
    update_attribute(:accepted_at, DateTime.now) if can_accept
    destroy if can_accept
  end

  def accepted?
    self.accepted_at.present?
  end

  def expired?
    return false unless expires?
    DateTime.now > self.expires_at
  end

  def expires?
    self.expires_at.present?
  end

  def is_pin?
    self.type == :pin
  end

  def type
    return @type.to_s.downcase.to_sym if @type
    return :pin if self.token && self.token.match(/^\d{4}$/)
    :token
  end

  private

  def generate_pin
    pin = ''
    4.times { pin += "#{rand(0..9)}" }
    pin
  end

  def reset_token
    self.token = type == :pin ? generate_pin : SecureRandom.uuid
  end

  def schedule_expiration_job
    expiration_rescheduled = expires? && self.expires_at_changed?
    new_record = new_record?
    yield
    reload if new_record
    reschedule_expiration_job = persisted? && valid? && expiration_rescheduled
    Resque.remove_delayed(InvitationExpirationJob, self.id) if reschedule_expiration_job
    Resque.enqueue_at(self.expires_at, InvitationExpirationJob, self.id) if reschedule_expiration_job
  end

  def unschedule_expiration_job
    yield
    Resque.remove_delayed(InvitationExpirationJob, self.id) if self.destroyed? && expires?
  end
end
