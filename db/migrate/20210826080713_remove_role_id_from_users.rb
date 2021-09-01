class RemoveRoleIdFromUsers < ActiveRecord::Migration[6.1]
  def change
    remove_column :users, :role_id, :integer
  end
end
