class RenameExpireAtColumn < ActiveRecord::Migration[6.1]
  def change
    rename_column :certs, :expire_at, :expires_at
    rename_column :certs, :url_expire_at, :url_expires_at
    rename_column :ip_white_lists, :expired_at, :expires_at
  end
end
