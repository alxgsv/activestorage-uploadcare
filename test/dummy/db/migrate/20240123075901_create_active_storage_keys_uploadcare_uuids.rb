class CreateActiveStorageKeysUploadcareUuids < ActiveRecord::Migration[6.0]
  def change
    create_table :active_storage_keys_uploadcare_uuids do |t|
      t.string :key
      t.string :uuid

      t.timestamps
    end
    add_index :active_storage_keys_uploadcare_uuids, :key, unique: true
    add_index :active_storage_keys_uploadcare_uuids, :uuid, unique: true
  end
end
