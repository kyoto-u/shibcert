class AddDetailsToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :number, :string
  end
end
