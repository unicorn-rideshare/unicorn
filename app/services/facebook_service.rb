class FacebookService

  class << self
    def api_client_factory(access_token = nil)
      access_token ||= "#{ENV['FACEBOOK_APP_ID']}|#{ENV['FACEBOOK_APP_SECRET']}"
      Koala::Facebook::API.new(access_token)
    end

    def debug_token(access_token)
      token = debug_token_raw(access_token)
      return nil unless token
      {
        app_id: token['data']['app_id'],
        expires_at: (DateTime.strptime(token['data']['expires_at'].to_s, '%s') rescue nil),
        issued_at: (DateTime.strptime(token['data']['issued_at'].to_s, '%s') rescue nil),
        is_valid: token['data']['is_valid'],
        metadata: token['data']['metadata'].try(:symbolize_keys),
        user_id: token['data']['user_id'],
      }
    end

    def debug_token_raw(access_token)
      api_client_factory().debug_token(access_token) rescue nil
    end

    def graph_object(access_token, path)
      api_client_factory(access_token).get_object(path)
    end
  end
end
