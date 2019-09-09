class AddDetailsToCerts < ActiveRecord::Migration
  def change
    add_column :certs, :download_type, :integer, :default => 1
  end
end
