class CreateActiveStorageKeysUploadcareUuids < ActiveRecord::Migration[6.0]
  def change
    create_table :active_storage_uploadcare_key_uuids, id: false do |t|
      t.string :key, null: false
      t.string :uuid, null: false
      t.index :key, unique: true
      t.index :uuid, unique: true
      t.timestamps
    end
  end
end
