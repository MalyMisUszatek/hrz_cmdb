class CreateHrzcmCiCustomFieldDefs < ActiveRecord::Migration[7.2]
  def up
    create_table :hrzcm_ci_custom_field_defs, if_not_exists: true do |t|
      t.integer  :j_ci_class_id, null: false
      t.string   :b_name,        null: false, limit: 120
      t.string   :b_key,         null: false, limit: 60
      t.string   :field_type,    null: false, default: 'text'
      # text / integer / float / date / bool / list
      t.text     :list_values    # JSON array, only for field_type='list'
      t.boolean  :is_required,   null: false, default: false
      t.string   :default_value, limit: 500
      t.integer  :j_sort,        null: false, default: 0
      t.timestamps
    end
    add_index :hrzcm_ci_custom_field_defs, :j_ci_class_id,
              name: 'idx_hrzcm_cfd_class'
    add_index :hrzcm_ci_custom_field_defs, [:j_ci_class_id, :b_key],
              unique: true, name: 'idx_hrzcm_cfd_class_key'
  end

  def down
    drop_table :hrzcm_ci_custom_field_defs
  end
end
