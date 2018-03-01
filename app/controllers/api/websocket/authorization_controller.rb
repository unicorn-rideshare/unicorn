module Api
  module Websocket
    class AuthorizationController < WebsocketRails::BaseController
      include Unicorn::TokenAuthenticatable

      def authorize_channels
        if authorize_resource
          accept_channel(current_user)
        else
          deny_channel(message: 'authorization failed')
        end
      end

      private

      def authorize_resource
        current_ability.can?(:read, resource) if resource
      end

      def channel
        WebsocketRails[message[:channel]]
      end

      def resource
        match = channel.name.to_s.match(/^([A-Za-z_]+)_/i)
        match[1].classify.constantize rescue nil if match
      end

      def resource_id
        match = channel.name.to_s.match(/\d+$/)
        match[0].to_i if match
      end

      def resource_instance
        @resource_instance ||= resource.find(resource_id) rescue nil
      end
    end
  end
end
