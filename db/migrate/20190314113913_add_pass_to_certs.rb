class AddPassToCerts < ActiveRecord::Migration
  def change
    add_column :certs, :pass_id, :string
    add_column :certs, :pass_pin, :string
    add_column :certs, :pass_p12, :string
  end
end
