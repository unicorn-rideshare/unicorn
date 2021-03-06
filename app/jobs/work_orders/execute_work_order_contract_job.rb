class ExecuteWorkOrderContractJob
  @queue = :high

  class << self
    def perform(work_order_id, jwt, wallet_id, method, params, value = 0)
      work_order = WorkOrder.unscoped.find(work_order_id) rescue nil
      contract_addr = work_order.try(:eth_contract_address)
      return unless work_order && contract_addr

      jwt ||= ENV['PROVIDE_APPLICATION_API_TOKEN']
      return unless jwt

      wallet_id ||= ENV['PROVIDE_DEFAULT_APPLICATION_WALLET_ID']
      return unless wallet_id

      status, _, resp = BlockchainService.execute_contract(jwt, contract_addr, { wallet_id: wallet_id, value: value, method: method, params: params })
      tx = nil
      if status == 202
        if resp['transaction']
          tx = resp['transaction']
        else
          tx_ref = resp['ref']
          while tx.nil?
            sleep(1.0)
            status, _, resp = BlockchainService.transaction_details(app_jwt, tx_ref)
            tx = resp if status == 200
          end
        end
        work_order.apply_broadcast_tx(tx) if tx
      end
      return status, tx
    end
  end
end
