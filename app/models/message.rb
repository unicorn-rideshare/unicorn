class Message < ActiveRecord::Base

  belongs_to :sender, class_name: User.name
  validates_presence_of :sender
  validates :sender_id, readonly: true, on: :update

  belongs_to :recipient, class_name: User.name
  validates_presence_of :recipient
  validates :recipient_id, readonly: true, on: :update

  validates :body, readonly: true, on: :update
  validates :media_url, readonly: true, on: :update
  validate :validate_body_or_media_url_presence

  default_scope { includes(:sender, :recipient).order('created_at desc') }

  scope :user_conversations, ->(user) {
    query = <<-EOF
      SELECT id FROM messages WHERE (LEAST(sender_id, recipient_id), GREATEST(sender_id, recipient_id), created_at)
      IN (SELECT LEAST(sender_id, recipient_id) as x, GREATEST(sender_id, recipient_id) as y, MAX(created_at) as created_at
      FROM messages WHERE sender_id = #{user.id} OR recipient_id = #{user.id} GROUP BY x, y)
    EOF
    where(id: find_by_sql(query).map(&:id))
  }

  after_create :deliver

  private

  def deliver
    Resque.enqueue(PushMessageNotificationsJob, self.id)
  end

  def validate_body_or_media_url_presence
    errors.add(:base, I18n.t('errors.message.nil_body_and_media_url')) unless self.body.present? || self.media_url.present?
  end
end
