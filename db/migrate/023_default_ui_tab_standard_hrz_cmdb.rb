class DefaultUiTabStandardHrzCmdb < ActiveRecord::Migration[7.2]
  def up
    change_column_default :hrzcm_ci_custom_field_defs, :ui_tab, 'standard'
    execute "UPDATE hrzcm_ci_custom_field_defs SET ui_tab = 'standard'"
  end

  def down
    change_column_default :hrzcm_ci_custom_field_defs, :ui_tab, 'other'
  end
end
