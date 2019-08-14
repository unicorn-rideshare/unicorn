class AddPaidFlagToWorkOrders < ActiveRecord::Migration
  def change
  	add_column :work_orders, :payment_remitted, :boolean, default: false
  	add_column :work_order_providers, :payment_remitted, :boolean, default: false

  	add_column :work_orders, :remittance_id, :string
  	add_column :work_order_providers, :remittance_id, :string

  	add_index :work_orders, [:payment_remitted], using: :btree
  	add_index :work_order_providers, [:payment_remitted], using: :btree
  end
end
