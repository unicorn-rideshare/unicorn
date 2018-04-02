class FetchContractCreationAddressJob
  @queue = :high

  class << self
    def perform(work_order_id, tx_id)
      work_order = WorkOrder.unscoped.find(work_order_id) rescue nil
      return unless work_order

      jwt = ENV['IDENT_APPLICATION_API_KEY']
      return unless jwt

      status, resp = BlockchainService.transaction_details(jwt, tx_id)
      contract_creation_addr = resp['traces']['result'].select { |result| result['type'].to_s.match(/^create$/i) }.first['result']['address']
      return unless contract_creation_addr

      work_order.update_attribute(:eth_contract_address, contract_creation_addr)
    end
  end
end
