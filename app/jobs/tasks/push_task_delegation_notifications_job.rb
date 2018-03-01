class PushTaskDelegationNotificationsJob
  include Unicorn::Notifications

  @queue = :high

  class << self
    def perform(task_id)
      new(task_id).process
    end
  end

  attr_reader :task

  def initialize(task_id)
    @task = Task.unscoped.find(task_id) rescue nil
  end

  def process
    return unless task
    send_push_notifications
  end

  private

  def alert
    I18n.t('notifications.tasks.apns_body').gsub(/\{\{ task_name \}\}/i, task.name.gsub(/@#{task.provider.contact.name}/i, '').strip).gsub(/\{\{ user_name \}\}/i, task.user.name)
  end

  def task_json
    Rabl::Renderer.new('tasks/show',
                       task,
                       view_path: 'app/views',
                       format: 'hash').render
  end

  def mobile_notification_params
    { message: task_json, alert: alert, sound: 'default' }
  end

  def users
    @users ||= [task.provider.user]
  end

  def websocket_notification_params
    { message: 'task.delegated', payload: task_json }
  end
end
