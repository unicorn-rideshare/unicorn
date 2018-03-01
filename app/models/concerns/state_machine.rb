module StateMachine
  extend ActiveSupport::Concern

  included do
    include AASM

    validate :status_valid?

    scope :by_status, lambda { |statuses|
      valid_statuses = self.aasm.states.map(&:name)
      filter_statuses = valid_statuses & statuses
      clauses = []
      filter_statuses.map do |status|
        clauses << "status = '#{status}'"
      end
      where(clauses.join(' OR ')) if clauses.length > 0
    }
  end

  def is_permissible_status?(status)
    aasm.states.map(&:name).include?(status.to_sym)
  end

  def permissible_events(status = nil)
    permissible_events = status.nil? ? aasm.permissible_events : []
    self.class.aasm.events.each do |event_key, event_obj|
      valid_transition = event_obj.transitions_from_state?(self.status.nil? ? nil : self.status.to_sym) &&
                         event_obj.transitions_to_state?(status.to_sym)
      permissible_events << event_key if valid_transition
    end if status
    permissible_events
  end

  private

  def status_valid?
    errors.add(:status, I18n.t('errors.messages.must_not_be_null')) if status.nil?
    errors.add(:status, I18n.t('errors.messages.not_included_in_list')) unless is_permissible_status?(status)
  end
end
