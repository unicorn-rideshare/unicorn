class Task < ActiveRecord::Base
  include Attachable
  include Commentable
  include StateMachine

  belongs_to :company
  validates :company, presence: true
  validates :company_id, readonly: true, on: :update

  belongs_to :category
  validate :category_must_belong_to_task_company

  belongs_to :task
  validates :task_id, readonly: true, on: :update, unless: lambda { self.task_id_was.nil? }

  belongs_to :user
  validates :user, presence: true
  validates :user_id, readonly: true, on: :update

  belongs_to :provider
  validates :provider_id, readonly: true, on: :update, unless: lambda { self.provider_id_was.nil? }
  validate :provider_must_belong_to_task_company

  belongs_to :job
  validates :job_id, readonly: true, on: :update, unless: lambda { self.job_id_was.nil? }
  validate :job_must_belong_to_task_company

  belongs_to :work_order
  validates :work_order_id, readonly: true, on: :update, unless: lambda { self.work_order_id_was.nil? }
  validate :work_order_must_belong_to_task_company

  # add :priority, :effort (man hours / cost), :materials (type / quantity / cost)

  validate :due_at_cannot_be_in_the_past, if: :due_at_changed?

  validate :validate_task_delegation, if: lambda { self.is_delegate? }

  validate :validate_provider_permissions

  after_save :enqueue_task_delegation_job, if: :provider_id_changed?

  default_scope { order('tasks.created_at DESC') }

  aasm column: :status, whiny_transitions: false do
    state :incomplete, initial: true
    state :declined
    state :pending_completion
    state :completed
    state :canceled

    event :decline do
      transitions from: [:incomplete], to: :declined

      before do
        self.declined_at = DateTime.now
      end
    end

    event :cancel do
      transitions from: [:incomplete, :pending_completion], to: :canceled

      before do
        self.canceled_at = DateTime.now
      end
    end

    event :close do
      transitions from: [:incomplete], to: :pending_completion
    end

    event :complete do
      transitions from: [:incomplete, :pending_completion], to: :completed, guard: :can_be_completed?

      before do
        self.completed_at = DateTime.now
      end
    end
  end
  
  def can_be_completed?
    status = self.status.to_s.underscore.to_sym
    return status == :pending_completion if has_delegate?
    [:incomplete, :pending_completion].include?(status)
  end

  def has_delegate?
    return false unless persisted?
    Task.where(task_id: self.id).size > 0
  end
  
  def is_delegate?
    self.task_id.present?
  end

  def delegate(provider)
    Task.create(company_id: self.company_id,
                category_id: self.category_id,
                task_id: self.id,
                user_id: provider.user_id,
                provider_id: provider.id,
                job_id: self.job_id,
                work_order_id: self.work_order_id,
                due_at: self.due_at,
                name: self.name,
                description: self.description)
  end

  def past_due?
    return false unless due_at.present?
    due_at < DateTime.now
  end

  private

  def category_must_belong_to_task_company
    return unless company_id && category_id
    match = company_id == category.company_id
    errors.add(:base, :task_company_category_confirmation) unless match
  end

  def provider_must_belong_to_task_company
    return unless company_id && provider_id
    match = company_id == provider.company_id
    errors.add(:base, :task_company_provider_confirmation) unless match
  end

  def job_must_belong_to_task_company
    return unless company_id && job_id
    match = company_id == job.company_id
    errors.add(:base, :task_company_job_confirmation) unless match
  end

  def work_order_must_belong_to_task_company
    return unless company_id && work_order_id
    match = company_id == work_order.company_id
    errors.add(:base, :task_company_work_order_confirmation) unless match
  end

  def enqueue_task_delegation_job
    return unless provider_id_changed?
    Resque.enqueue(PushTaskDelegationNotificationsJob, self.id)
  end

  def due_at_cannot_be_in_the_past
    errors.add(:due_at, I18n.t('errors.messages.must_not_be_in_past')) if due_at && due_at < DateTime.now
  end

  def validate_provider_permissions
    return unless provider_id
    errors.add(:base, I18n.t('errors.messages.task_delegation_must_remain_in_task_company')) unless company_id == provider.company_id
  end

  def validate_task_delegation
    return unless task_id && provider_id
    errors.add(:base, I18n.t('errors.messages.task_delegation_must_remain_in_task_company')) unless task.company_id == company_id
    #errors.add(:base, I18n.t('errors.messages.task_delegation_must_be_initiated_by_task_provider')) unless task.user_id == provider.user_id
  end
end
