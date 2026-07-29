class AddUiTabToCustomFieldDefsHrzCmdb < ActiveRecord::Migration[7.2]
  def change
    unless column_exists?(:hrzcm_ci_custom_field_defs, :ui_tab)
      add_column :hrzcm_ci_custom_field_defs, :ui_tab, :string, limit: 20,
                 null: false, default: 'other'
    end
  end
end
