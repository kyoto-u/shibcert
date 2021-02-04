class AddDetailsToCerts < ActiveRecord::Migration[4.2]
  def change
    add_column :certs, :download_type, :integer, :default => 1
  end
end
