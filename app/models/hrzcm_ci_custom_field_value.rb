#-------------------------------------------------------------------------------------eohdr-
# Purpose: Stores actual custom field values per CI instance.
#          value is always stored as string, cast on read via field_def.cast_value
#-------------------------------------------------------------------------------------eohdr-
class HrzcmCiCustomFieldValue < ActiveRecord::Base
  self.table_name = 'hrzcm_ci_custom_field_values'

  belongs_to :ci,        class_name: 'HrzcmCi',               foreign_key: 'j_ci_id'
  belongs_to :field_def, class_name: 'HrzcmCiCustomFieldDef',  foreign_key: 'j_field_def_id'

  validates :j_ci_id,        presence: true
  validates :j_field_def_id, presence: true
  validates :j_field_def_id, uniqueness: { scope: :j_ci_id }

  after_create  :log_cf_create
  after_update  :log_cf_update
  after_destroy :log_cf_destroy

  # Returns typed value via field_def
  def typed_value
    field_def.cast_value(value)
  end

  def display_value
    return '✓' if field_def.field_type == 'bool' && value == '1'
    return '✗' if field_def.field_type == 'bool'
    typed_value.to_s
  end

  def fieldlabel
    if fielddef.respond_to?(:bname) && fielddef.bname.present?
      fielddef.bname
    else
      "CF\#{j_fielddef_id}"
    end
  end

  private

  def field_label
    field_def&.b_name || field_def&.b_name_en || "CF##{j_field_def_id}"
  end

  def log_cf_create
    return unless ci
    HrzcmCiAudit.log(ci, action: 'update',
      field: field_label, old_val: nil, new_val: display_value)
  end

  def log_cf_update
    return unless ci && saved_change_to_attribute?(:value)
    old_raw, new_raw = saved_change_to_attribute(:value)
    old_disp = field_def.cast_value(old_raw).to_s
    new_disp = display_value
    HrzcmCiAudit.log(ci, action: 'update',
      field: field_label, old_val: old_disp, new_val: new_disp)
  end

  def log_cf_destroy
    return unless ci
    HrzcmCiAudit.log(ci, action: 'update',
      field: field_label, old_val: display_value, new_val: nil)
  end
end
