class WorkOrderProvider < ActiveRecord::Base
  include Invitable
  include Notifiable

  belongs_to :provider
  validates :provider, presence: true
  validates :provider_id, readonly: true, on: :update
  validate :providers_company_must_match

  belongs_to :work_order, inverse_of: :work_order_providers
  validates :work_order, presence: true
  validates :work_order_id, readonly: true, on: :update

  default_scope { includes(:provider).order('id') }

  scope :not_timed_out, ->{ where('work_order_providers.timed_out_at IS NULL') }

  scope :timed_out, ->{ where('work_order_providers.timed_out_at IS NOT NULL') }

  def confirm(confirmed_at)
    return if confirmed?
    confirmed_at = DateTime.parse(confirmed_at) rescue DateTime.now
    update_attribute(:confirmed_at, confirmed_at)
    work_order.route! if work_order.status.to_sym == :pending_acceptance
  end

  def confirmed?
    !confirmed_at.nil?
  end

  def estimated_cost
    return nil unless flat_fee_due || (estimated_duration && hourly_rate_due && estimated_duration >= 0.0 && hourly_rate_due >= 0.0)
    cost = flat_fee_due || 0.0
    cost += ((estimated_duration / 3600.0) * hourly_rate_due).round(2) rescue 0.0
    cost.round(2)
  end

  def estimated_revenue
    return nil unless flat_fee || (estimated_duration && hourly_rate && estimated_duration >= 0.0 && hourly_rate >= 0.0)
    cost = flat_fee || 0.0
    cost += ((estimated_duration / 3600.0) * hourly_rate).round(2) rescue 0.0
    cost.round(2)
  end

  def user
    provider.user
  end

  private

  def nil_provider_company?
    provider.company.nil?
  end

  def providers_company_must_match
    return unless provider_id && work_order_id && provider.company_id && work_order.company_id
    match = provider.company_id == work_order.company_id
    errors.add(:provider_id, :work_order_company_confirmation) unless match
  end

  def invitation_received(invitation)
    Resque.enqueue(SendInvitationJob, invitation.id)
  end

  def notification_params(notification_type)
    {
        id: self.id,
        provider_id: self.provider_id,
        work_order_id: self.work_order_id,
        user_id: self.user.id,
        confirmed: self.confirmed?,
        timed_out: self.timed_out_at.present?,
    }
  end

  def notification_recipients(notification_type)
    user.nil? ? [] : [user]
  end
end
