class CreateIdentities < ActiveRecord::Migration[6.1]
  def change
    create_table :identities do |t|
      t.string :uid
      t.string :name
      t.string :email
      t.string :password_digest

      t.timestamps
    end
  end
end
