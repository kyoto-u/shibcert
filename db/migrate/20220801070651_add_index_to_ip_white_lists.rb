class AddIndexToIpWhiteLists < ActiveRecord::Migration[6.1]
  def change
    add_index :ip_white_lists, :ip, unique: true
  end
end
