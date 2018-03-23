class AddConfigToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :config, :json, default: {}
  end
end
