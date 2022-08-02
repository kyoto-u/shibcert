class RenameProtectColumn < ActiveRecord::Migration[6.1]
  def change
    rename_column :ip_white_lists, :protect, :protected
  end
end
