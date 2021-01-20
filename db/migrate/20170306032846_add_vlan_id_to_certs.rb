class AddVlanIdToCerts < ActiveRecord::Migration[4.2]
  def change
    add_column :certs, :vlan_id, :string
  end
end
