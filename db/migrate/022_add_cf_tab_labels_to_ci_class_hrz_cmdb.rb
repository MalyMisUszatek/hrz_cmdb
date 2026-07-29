class AddCfTabLabelsToCiClassHrzCmdb < ActiveRecord::Migration[7.2]
  def change
    add_column :hrzcm_ci_class, :cf_tab_standard_label, :string, limit: 60
    add_column :hrzcm_ci_class, :cf_tab_other_label,    :string, limit: 60
  end
end
