class AddCfDescriptionToFieldDefs < ActiveRecord::Migration[7.2]
  def up
    add_column :hrzcm_ci_custom_field_defs, :bdescription, :string, limit: 500, null: true unless
      column_exists?(:hrzcm_ci_custom_field_defs, :bdescription)
  end
  def down
    remove_column :hrzcm_ci_custom_field_defs, :bdescription if
      column_exists?(:hrzcm_ci_custom_field_defs, :bdescription)
  end
end
