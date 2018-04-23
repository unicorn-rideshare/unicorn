class FetchContractCreationAddressJob
  @queue = :high

  class << self
    def perform(work_order_id, tx_id)
      work_order = WorkOrder.unscoped.find(work_order_id) rescue nil
      return unless work_order

      network_id = ENV['PROVIDE_NETWORK_ID']
      jwt = ENV['PROVIDE_APPLICATION_API_TOKEN']
      return unless network_id && jwt

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

        BlockchainService.create_contract(jwt, {name: 'UnicornRide', address: contract_creation_addr, network_id: network_id, params: {abi: JSON.parse(unicorn_ride_abi)}})
        work_order.update_attribute(:eth_contract_address, contract_creation_addr)
      end
    end

    def unicorn_ride_abi
      <<-EOF
      [
        {
          "constant": true,
          "inputs": [],
          "name": "provider",
          "outputs": [
            {
              "name": "",
              "type": "address"
            }
          ],
          "payable": false,
          "stateMutability": "view",
          "type": "function"
        },
        {
          "constant": true,
          "inputs": [],
          "name": "peer",
          "outputs": [
            {
              "name": "",
              "type": "address"
            }
          ],
          "payable": false,
          "stateMutability": "view",
          "type": "function"
        },
        {
          "constant": true,
          "inputs": [],
          "name": "status",
          "outputs": [
            {
              "name": "",
              "type": "uint8"
            }
          ],
          "payable": false,
          "stateMutability": "view",
          "type": "function"
        },
        {
          "constant": false,
          "inputs": [
            {
              "name": "_amount",
              "type": "uint256"
            },
            {
              "name": "_details",
              "type": "string"
            }
          ],
          "name": "complete",
          "outputs": [],
          "payable": false,
          "stateMutability": "nonpayable",
          "type": "function"
        },
        {
          "constant": true,
          "inputs": [],
          "name": "unicorn",
          "outputs": [
            {
              "name": "",
              "type": "address"
            }
          ],
          "payable": false,
          "stateMutability": "view",
          "type": "function"
        },
        {
          "constant": true,
          "inputs": [],
          "name": "details",
          "outputs": [
            {
              "name": "",
              "type": "string"
            }
          ],
          "payable": false,
          "stateMutability": "view",
          "type": "function"
        },
        {
          "constant": true,
          "inputs": [],
          "name": "identifier",
          "outputs": [
            {
              "name": "",
              "type": "uint128"
            }
          ],
          "payable": false,
          "stateMutability": "view",
          "type": "function"
        },
        {
          "constant": true,
          "inputs": [],
          "name": "paymentEscrow",
          "outputs": [
            {
              "name": "",
              "type": "address"
            }
          ],
          "payable": false,
          "stateMutability": "view",
          "type": "function"
        },
        {
          "constant": true,
          "inputs": [],
          "name": "amount",
          "outputs": [
            {
              "name": "",
              "type": "uint256"
            }
          ],
          "payable": false,
          "stateMutability": "view",
          "type": "function"
        },
        {
          "constant": false,
          "inputs": [],
          "name": "completeTransaction",
          "outputs": [],
          "payable": false,
          "stateMutability": "nonpayable",
          "type": "function"
        },
        {
          "constant": true,
          "inputs": [],
          "name": "unicornWallet",
          "outputs": [
            {
              "name": "",
              "type": "address"
            }
          ],
          "payable": false,
          "stateMutability": "view",
          "type": "function"
        },
        {
          "constant": false,
          "inputs": [
            {
              "name": "_provider",
              "type": "address"
            }
          ],
          "name": "start",
          "outputs": [],
          "payable": false,
          "stateMutability": "nonpayable",
          "type": "function"
        },
        {
          "constant": false,
          "inputs": [],
          "name": "cancel",
          "outputs": [],
          "payable": false,
          "stateMutability": "nonpayable",
          "type": "function"
        },
        {
          "constant": true,
          "inputs": [],
          "name": "token",
          "outputs": [
            {
              "name": "",
              "type": "address"
            }
          ],
          "payable": false,
          "stateMutability": "view",
          "type": "function"
        },
        {
          "inputs": [
            {
              "name": "_token",
              "type": "address"
            },
            {
              "name": "_unicorn",
              "type": "address"
            },
            {
              "name": "_unicornWallet",
              "type": "address"
            },
            {
              "name": "_paymentEscrow",
              "type": "address"
            },
            {
              "name": "_peer",
              "type": "address"
            },
            {
              "name": "_identifier",
              "type": "uint128"
            }
          ],
          "payable": false,
          "stateMutability": "nonpayable",
          "type": "constructor"
        },
        {
          "anonymous": false,
          "inputs": [
            {
              "indexed": false,
              "name": "_identifier",
              "type": "uint128"
            }
          ],
          "name": "WorkOrderStarted",
          "type": "event"
        },
        {
          "anonymous": false,
          "inputs": [
            {
              "indexed": false,
              "name": "_identifier",
              "type": "uint128"
            }
          ],
          "name": "WorkOrderCanceled",
          "type": "event"
        },
        {
          "anonymous": false,
          "inputs": [
            {
              "indexed": false,
              "name": "_identifier",
              "type": "uint128"
            },
            {
              "indexed": false,
              "name": "_amount",
              "type": "uint256"
            },
            {
              "indexed": false,
              "name": "_details",
              "type": "string"
            }
          ],
          "name": "WorkOrderCompleted",
          "type": "event"
        },
        {
          "anonymous": false,
          "inputs": [
            {
              "indexed": false,
              "name": "_identifier",
              "type": "uint128"
            },
            {
              "indexed": false,
              "name": "_paymentAmount",
              "type": "uint256"
            },
            {
              "indexed": false,
              "name": "feeAmount",
              "type": "uint256"
            },
            {
              "indexed": false,
              "name": "_details",
              "type": "string"
            }
          ],
          "name": "TransactionCompleted",
          "type": "event"
        }
      ]
EOF
    end
  end
end
