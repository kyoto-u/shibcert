class CreateUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :users do |t|
      t.string :uid
      t.string :name
      t.string :email
      t.integer :role_id

      t.timestamps
    end
  end
end
