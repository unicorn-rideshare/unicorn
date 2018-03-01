class Comment < ActiveRecord::Base
  include Attachable
  include Notifiable

  belongs_to :commentable, polymorphic: true
  validates :commentable_id, readonly: true, on: :update
  validates :commentable_type, readonly: true, on: :update

  belongs_to :user
  validates :user, presence: true

  default_scope { order('comments.created_at DESC') }

  scope :greedy, ->() { includes(:attachments) }

  def previous_comment_id
    @previous_comment_id ||= begin
      previous_comment_index = self.commentable.comment_ids.reverse.index(self.id) - 1 rescue nil
      previous_comment_index = nil if previous_comment_index && previous_comment_index <= 0
      self.commentable.comment_ids.reverse[previous_comment_index] rescue nil
    end
  end

  def save!
    raise ActiveRecord::ReadOnlyRecord if persisted?
    super
  end

  private

  def notification_params(notification_type)
    {
        comment: Rabl::Renderer.new('comments/show',
                                    self,
                                    view_path: 'app/views',
                                    format: 'hash').render
    }
  end

  def notification_recipients(notification_type)
    recipients = [self.user]
    recipients += self.commentable.send(:notification_recipients, notification_type) rescue [] if self.commentable.is_a?(Notifiable)
    recipients.uniq
  end
end
