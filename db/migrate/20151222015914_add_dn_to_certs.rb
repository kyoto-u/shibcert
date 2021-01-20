class AddDnToCerts < ActiveRecord::Migration[4.2]
  def change
    add_column :certs, :dn, :string
  end
end
