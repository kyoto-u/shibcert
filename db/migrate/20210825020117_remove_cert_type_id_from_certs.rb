class RemoveCertTypeIdFromCerts < ActiveRecord::Migration[6.1]
  def change
    remove_column :certs, :cert_type_id, :integer
  end
end
