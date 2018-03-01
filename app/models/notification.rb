class Notification < ActiveRecord::Base

  belongs_to :notifiable, polymorphic: true
  validates :notifiable_id, readonly: true, on: :update
  validates :notifiable_type, readonly: true, on: :update

  belongs_to :recipient, class_name: User.name
  validates :recipient, presence: true
  validates :recipient_id, readonly: true, on: :update

  validates :type, inclusion: { in: Settings.app.notification_types, allow_nil: true }

  after_create :deliver

  attr_accessor :params

  class << self
    def inheritance_column
      'subclass'
    end
  end

  private

  def deliver
    params = self.params || {}
    Resque.enqueue(PushNotificationJob, self.id, params)
  end
end
