class AddStripeBankAccountSupport < ActiveRecord::Migration
  def change
  	add_column :companies, :stripe_bank_account_id, :string
  	add_column :providers, :stripe_bank_account_id, :string
  end
end
