class AddStripeAccountId < ActiveRecord::Migration
  def change
  	add_column :providers, :stripe_account_id, :string
  end
end
