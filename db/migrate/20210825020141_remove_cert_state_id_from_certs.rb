class RemoveCertStateIdFromCerts < ActiveRecord::Migration[6.1]
  def change
    remove_column :certs, :cert_state_id, :integer
  end
end
