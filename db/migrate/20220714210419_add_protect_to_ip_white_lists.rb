class AddProtectToIpWhiteLists < ActiveRecord::Migration[6.1]
  def change
    add_column :ip_white_lists, :protect, :boolean, default: false
  end
end
