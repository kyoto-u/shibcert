class AddUrlExpireAtToCerts < ActiveRecord::Migration[4.2]
  def change
    add_column :certs, :url_expire_at, :datetime
  end
end
