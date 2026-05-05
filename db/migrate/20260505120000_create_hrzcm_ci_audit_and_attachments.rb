class CreateHrzcmCiAuditAndAttachments < ActiveRecord::Migration[7.2]
  def up
    create_table :hrzcm_ci_audit do |t|
      t.integer  :ci_id,        null: false
      t.integer  :user_id
      t.string   :action,       null: false, default: 'update'
      t.string   :field_name
      t.text     :old_value
      t.text     :new_value
      t.string   :note,         limit: 512
      t.datetime :created_at,   null: false
    end
    add_index :hrzcm_ci_audit, :ci_id
    add_index :hrzcm_ci_audit, :created_at

    create_table :hrzcm_ci_attachments do |t|
      t.integer  :ci_id,         null: false
      t.integer  :user_id
      t.string   :filename,      null: false
      t.string   :description,   limit: 512
      t.string   :content_type,  limit: 100
      t.integer  :filesize,      default: 0
      t.string   :disk_filename, null: false
      t.datetime :created_at,    null: false
    end
    add_index :hrzcm_ci_attachments, :ci_id
  end

  def down
    drop_table :hrzcm_ci_attachments
    drop_table :hrzcm_ci_audit
  end
end
