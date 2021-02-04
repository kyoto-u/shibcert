class RemoveNameFromCerts < ActiveRecord::Migration[4.2]
  def change
    remove_column :certs, :name, :string
  end
end
