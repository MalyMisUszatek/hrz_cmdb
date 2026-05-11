class CreateHrzcmCiCustomFieldValues < ActiveRecord::Migration[7.2]
  def up
    create_table :hrzcm_ci_custom_field_values, if_not_exists: true do |t|
      t.integer :j_ci_id,       null: false
      t.integer :j_field_def_id, null: false
      t.text    :value
      t.timestamps
    end
    add_index :hrzcm_ci_custom_field_values, [:j_ci_id, :j_field_def_id],
              unique: true, name: 'idx_hrzcm_cfv_ci_field'
    add_index :hrzcm_ci_custom_field_values, :j_field_def_id,
              name: 'idx_hrzcm_cfv_field_def'
  end

  def down
    drop_table :hrzcm_ci_custom_field_values
  end
end
