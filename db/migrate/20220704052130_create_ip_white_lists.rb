class CreateIpWhiteLists < ActiveRecord::Migration[6.1]
  def change
    create_table :ip_white_lists do |t|
      t.string :ip
      t.datetime :expired_at
      t.string :memo

      t.timestamps
    end
  end
end
