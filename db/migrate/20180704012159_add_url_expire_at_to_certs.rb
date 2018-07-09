class AddUrlExpireAtToCerts < ActiveRecord::Migration
  def change
    add_column :certs, :url_expire_at, :datetime
  end
end
