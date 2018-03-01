class ProviderBecameUnavailableJob
  include Unicorn::Notifications

  @queue = :high

  class << self
    def perform(provider_id)
      provider = Provider.unscoped.find(provider_id) rescue nil
      return unless provider

      new(provider).process
    end
  end

  def initialize(provider)
    @provider = provider
  end

  def process
    send_push_notifications
  end

  def mobile_notification_params
    {
        type: 'provider_became_unavailable',
        provider_id: @provider.id,
    }
  end

  def users
    @users ||= begin
      coord = Coordinate.new(@provider.last_checkin_latitude, @provider.last_checkin_longitude) rescue nil
      return User.nearby(coord, 50).to_a if coord
      []
    end
  end

  def websocket_notification_params
    {
      message: 'provider_became_unavailable',
      payload: {
        provider_id: @provider.id
      }
    }
  end
end
