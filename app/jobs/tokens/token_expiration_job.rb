class TokenExpirationJob
  @queue = :high

  class << self
    def perform(token_id)
      token = Token.unscoped.find(token_id) rescue nil
      token.destroy if token && token.expired?
    end
  end
end
