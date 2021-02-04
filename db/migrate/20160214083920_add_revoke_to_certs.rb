class AddRevokeToCerts < ActiveRecord::Migration[4.2]
  def change
    add_column :certs, :revoke_reason, :integer
    add_column :certs, :revoke_comment, :string
  end
end
