class AddSerialnumberToCerts < ActiveRecord::Migration[4.2]
  def change
    add_column :certs, :serialnumber, :string
  end
end
