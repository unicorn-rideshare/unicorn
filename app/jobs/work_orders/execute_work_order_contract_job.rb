class ExecuteWorkOrderContractJob
  @queue = :high

  class << self
    def perform(work_order_id, jwt, method, params, value = 0)
      work_order = WorkOrder.unscoped.find(work_order_id) rescue nil
      contract_addr = work_order.try(:eth_contract_address)
      return unless work_order && contract_addr

      jwt ||= ENV['PROVIDE_APPLICATION_API_TOKEN']
      return unless jwt

      wallet_id = ENV['PROVIDE_DEFAULT_APPLICATION_WALLET_ID']
      return unless wallet_id

      status, resp = BlockchainService.execute_contract(jwt, contract_addr, { wallet_id: wallet_id, value: value, method: method, params: params })
      tx = nil
      if status == 202
        tx = resp['transaction']
        work_order.apply_broadcast_tx(tx) if tx
      end
      return status, tx
    end
  end
end
