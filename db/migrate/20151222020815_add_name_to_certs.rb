class AddNameToCerts < ActiveRecord::Migration[4.2]
  def change
    add_column :certs, :memo, :string
  end
end
