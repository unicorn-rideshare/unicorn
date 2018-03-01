class ProviderLocationChangedJob
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
        type: 'provider_location_changed',
        provider_id: @provider.id,
    }
  end

  def users
    @users ||= begin
      coord = Coordinate.new(@provider.last_checkin_latitude, @provider.last_checkin_longitude) rescue nil
      return User.active.nearby(coord, 50).to_a if coord
      []
    end
  end

  def websocket_notification_params
    payload = Rabl::Renderer.new('providers/show',
                                 @provider,
                                 view_path: 'app/views',
                                 format: 'hash').render rescue nil

    { message: 'provider_location_changed', payload: payload }
  end
end
