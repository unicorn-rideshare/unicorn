class FetchContractCreationAddressJob
  @queue = :high

  class << self
    def perform(work_order_id, tx_id)
      work_order = WorkOrder.unscoped.find(work_order_id) rescue nil
      return unless work_order

      jwt = ENV['IDENT_APPLICATION_API_KEY']
      return unless jwt

      status, resp = BlockchainService.transaction_details(jwt, tx_id)
      if status == 200
        _trace = resp['traces']['result']
        while _trace.nil?
          sleep(1.0)
          status, resp = BlockchainService.transaction_details(jwt, tx_id)
          if status == 200
            _trace = resp['traces']['result']
          else
            raise RuntimeError("Received invalid status code from tx details API: #{status}")
          end
        end
        
        contract_creation_addr = _trace.select { |_trace| _trace['type'].to_s.match(/^create$/i) }.first['result']['address'] rescue nil
        return unless contract_creation_addr

        BlockchainService.create_contract({name: 'UnicornRide', address: contract_creation_addr})
        work_order.update_attribute(:eth_contract_address, contract_creation_addr)
      end
    end
  end
end
