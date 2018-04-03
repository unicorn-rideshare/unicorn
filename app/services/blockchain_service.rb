class BlockchainService
  class << self

    def goldmine(jwt_token)
      Provide::Services::Goldmine.new((ENV['GOLDMINE_API_SCHEME'] || 'http'), ENV['GOLDMINE_API_HOST'], jwt_token)
    end

    def balances(jwt_token, wallet_id, token_id)
      goldmine(jwt_token).wallet_balance(wallet_id, token_id)
    end

    def contracts(jwt_token, filter_tokens = false)
      params = {}
      params[:filter_tokens] = filter_tokens if filter_tokens
      goldmine(jwt_token).contracts(params)
    end

    def create_contract(jwt_token, params)
      goldmine(jwt_token).create_contract(params)
    end

    def execute_contract(jwt_token, contract_id, params)
      goldmine(jwt_token).execute_contract(contract_id, params)
    end

    def networks(jwt_token)
      goldmine(jwt_token).networks
    end

    def network_details(jwt_token, network_id)
      goldmine(jwt_token).network_details(network_id)
    end

    def network_status(jwt_token, network_id)
      goldmine(jwt_token).network_status(network_id)
    end

    def prices(jwt_token)
      goldmine(jwt_token).prices
    end

    def tokens(jwt_token)
      goldmine(jwt_token).tokens
    end

    def create_token(jwt_token, params)
      goldmine(jwt_token).create_token(params)
    end

    def transactions(jwt_token, filter_contract_creations = false)
      params = {}
      params[:filter_contract_creations] = filter_contract_creations if filter_contract_creations
      goldmine(jwt_token).transactions(params)
    end

    def transaction_details(jwt_token, tx_id)
      goldmine(jwt_token).transaction_details(tx_id)
    end

    def create_transaction(jwt_token, params)
      goldmine(jwt_token).create_transaction(params)
    end

    def wallets(jwt_token)
      goldmine(jwt_token).wallets
    end

    def create_wallet(jwt_token, params)
      return nil unless params[:network_id]
      goldmine(jwt_token).create_wallet(params)
    end
  end
end
