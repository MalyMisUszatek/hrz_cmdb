#-------------------------------------------------------------------------------------eohdr-
# Purpose: Defines custom field schema per CiClass.
#          field_type: text | integer | float | date | bool | list
#          list_values: JSON array of strings (only for type=list)
#-------------------------------------------------------------------------------------eohdr-
class HrzcmCiCustomFieldDef < ActiveRecord::Base
  self.table_name = 'hrzcm_ci_custom_field_defs'

  FIELD_TYPES = %w[text integer float date bool list].freeze

  belongs_to :ci_class, class_name: 'HrzcmCiClass', foreign_key: 'j_ci_class_id'
  has_many   :field_values, class_name: 'HrzcmCiCustomFieldValue',
             foreign_key: 'j_field_def_id', dependent: :destroy

  validates :b_name,      presence: true, length: { maximum: 120 }
  validates :b_key,       presence: true, length: { maximum: 60 },
            format: { with: /\A[a-z0-9_]+\z/, message: 'only lowercase letters, digits, underscore' },
            uniqueness: { scope: :j_ci_class_id }
  validates :field_type,  inclusion: { in: FIELD_TYPES }
  validates :j_sort,      numericality: { only_integer: true }

  default_scope { order(:j_sort, :b_name) }

  # Parse list_values JSON -> Array
  def list_options
    return [] unless field_type == 'list' && list_values.present?
    JSON.parse(list_values)
  rescue
    []
  end

  # Set list_values from Array
  def list_options=(arr)
    self.list_values = arr.is_a?(Array) ? arr.to_json : arr
  end

  # Cast string value to proper Ruby type for display
  def cast_value(raw)
    return nil if raw.blank?
    case field_type
    when 'integer' then raw.to_i
    when 'float'   then raw.to_f
    when 'date'    then Date.parse(raw) rescue raw
    when 'bool'    then raw == '1' || raw == 'true'
    else raw
    end
  end

  # Human-readable type label
  def field_type_label
    I18n.t("hrz_cmdb.custom_fields.types.#{field_type}", default: field_type)
  end
end
