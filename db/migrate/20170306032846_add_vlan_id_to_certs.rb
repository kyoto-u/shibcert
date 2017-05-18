class AddVlanIdToCerts < ActiveRecord::Migration
  def change
    add_column :certs, :vlan_id, :string
  end
end
