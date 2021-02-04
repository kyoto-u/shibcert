class AddColumnToCert < ActiveRecord::Migration[4.2]
  def change
    add_column :certs, :req_seq, :integer
  end
end
