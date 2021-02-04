class AddStatePurposeTypeToCert < ActiveRecord::Migration[4.2]
  def change
    add_column :certs, :state, :integer
    add_column :certs, :purpose_type, :integer
  end
end
