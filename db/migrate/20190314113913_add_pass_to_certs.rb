class AddPassToCerts < ActiveRecord::Migration[4.2]
  def change
    add_column :certs, :pass_id, :string
    add_column :certs, :pass_pin, :string
    add_column :certs, :pass_p12, :string
  end
end
