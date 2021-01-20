class AddColumnToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :cert_serial_max, :integer, :default => 0;
  end
end
