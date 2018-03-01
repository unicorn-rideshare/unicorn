module WorkOrderSettings
  extend ActiveSupport::Concern

  included do
    def config
      super.with_indifferent_access
    end

    def update_config(cfg)
      self.config = cfg.with_indifferent_access
      save
    end

    def default_customer_communications_config
      {
          communications_enabled: false,
          email_scheduled_confirmation_offset: 7.days.seconds * -1, # offset from work order scheduled start at
          email_reminder_offset: 1.day.seconds * -1, # offset from work order scheduled start at
          email_morning_of_reminder_offset: 8.hours.seconds, # offset from midnight of work order scheduled start at date
          email_upon_abandoned_follow_up_offset: 0.seconds, # offset from the abandonment of work order to when customer receives follow up
          email_upon_completion_follow_up_offset: 0.seconds, # offset from the completion of work order to when customer receives follow up
          exposes_status_publicly: true, # when true, allows anonymous users to view provider location and work order details on a map
          rating_request_dial_offset: nil
      }.with_indifferent_access
    end

    def default_dot_hours_of_service_config
      {
          off_duty_min: 10.hours / 3600.0,
          daily_driving_max: 11.hours / 3600.0,
          daily_aggregate_max: 14.hours / 3600.0,
          rest_lapse_interval: 8.hours / 3600.0,
          rest_min: 30.minutes / 3600.0
      }.with_indifferent_access
    end
  end
end
