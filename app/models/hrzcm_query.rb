class HrzcmQuery < ActiveRecord::Base
  self.table_name = 'hrzcm_queries'

  belongs_to :user

  validates :name, presence: true, length: { maximum: 255 }
  validates :entity_type, presence: true,
            inclusion: { in: %w[ci location ci_class lifecycle_status] }
  validates :user_id, presence: true

  before_create { self.created_on = self.updated_on = Time.now }
  before_update { self.updated_on = Time.now }

  ENTITY_TYPES   = %w[ci location ci_class lifecycle_status].freeze
  RELATION_TYPES = %w[connected_to contains installed_on runs_on virtualizes].freeze

  AVAILABLE_COLUMNS = {
    'ci' => [
      ['b_name_full',   :field_b_name_full],
      ['b_name_abbr',   :field_b_name_abbr],
      ['j_ci_class_id', :field_j_ci_class_id],
      ['j_location_id', :field_j_location_id],
      ['j_status_id',   :field_j_status_id],
      ['b_producer',    :field_b_producer],
      ['b_model',       :field_b_model],
      ['b_tag_serial',  :field_b_tag_serial],
      ['relations_out', :field_relations_out],
      ['relations_in',  :field_relations_in],
      ['created_on',    :field_created_on],
      ['updated_on',    :field_updated_on]
    ],
    'location' => [
      ['b_name_full',   :field_b_name_full],
      ['b_name_abbr',   :field_b_name_abbr],
      ['b_key',         :field_b_key],
      ['j_type_id',     :field_j_type_id],
      ['j_part_of1_id', :field_j_part_of1_id],
      ['created_on',    :field_created_on],
      ['updated_on',    :field_updated_on]
    ],
    'ci_class' => [
      ['b_name_full',      :field_b_name_full],
      ['b_name_abbr',      :field_b_name_abbr],
      ['b_key',            :field_b_key],
      ['j_subclass_of_id', :field_j_subclass_of_id],
      ['j_sort',           :field_j_sort],
      ['created_on',       :field_created_on],
      ['updated_on',       :field_updated_on]
    ],
    'lifecycle_status' => [
      ['b_key',       :field_b_key],
      ['b_name_full', :field_b_name_full],
      ['b_name_abbr', :field_b_name_abbr],
      ['created_on',  :field_created_on],
      ['updated_on',  :field_updated_on]
    ]
  }.freeze

  TEXT_FIELDS     = %w[b_name_full b_name_abbr b_key b_producer b_model b_tag_serial].freeze
  FK_FIELDS       = %w[j_ci_class_id j_location_id j_status_id j_type_id j_part_of1_id j_subclass_of_id].freeze
  DATE_FIELDS     = %w[created_on updated_on].freeze
  VIRTUAL_FIELDS  = %w[relations_out relations_in].freeze
  RELATION_FILTER = 'has_relation_type'.freeze

  def filters_data
    return [] if filters.blank?
    data = filters.is_a?(String) ? JSON.parse(filters) : filters
    data.is_a?(Array) ? data : []
  rescue JSON::ParserError
    []
  end

  def columns_data
    return [] if columns.blank?
    data = columns.is_a?(String) ? JSON.parse(columns) : columns
    (data.is_a?(Array) && data.any?) ? data : default_columns
  rescue JSON::ParserError
    default_columns
  end

  def default_columns
    case entity_type
    when 'ci'               then %w[b_name_full b_name_abbr j_ci_class_id j_location_id j_status_id]
    when 'location'         then %w[b_name_full b_name_abbr b_key j_type_id]
    when 'ci_class'         then %w[b_name_full b_name_abbr b_key]
    when 'lifecycle_status' then %w[b_key b_name_full b_name_abbr]
    else []
    end
  end

  def entity_model
    {
      'ci'               => HrzcmCi,
      'location'         => HrzcmLocation,
      'ci_class'         => HrzcmCiClass,
      'lifecycle_status' => HrzcmLifecycleStatus
    }[entity_type]
  end

  def results_scope
    model = entity_model
    return HrzcmCi.none unless model
    apply_sort(apply_filters(model.all))
  end

  def apply_filters(scope)
    filters_data.each do |f|
      field    = f['field'].to_s
      operator = f['operator'].to_s
      value    = f['value'].to_s

      if field == RELATION_FILTER
        case value
        when 'any'
          scope = scope.joins(
            "INNER JOIN hrzcm_ci_relations r
             ON r.source_ci_id = hrzcm_ci.id OR r.target_ci_id = hrzcm_ci.id"
          ).distinct
        when 'none'
          scope = scope.where(
            "NOT EXISTS (SELECT 1 FROM hrzcm_ci_relations r
              WHERE r.source_ci_id = hrzcm_ci.id OR r.target_ci_id = hrzcm_ci.id)"
          )
        else
          if RELATION_TYPES.include?(value)
            quoted = HrzcmCi.connection.quote(value)
            scope = scope.joins(
              "INNER JOIN hrzcm_ci_relations r
               ON (r.source_ci_id = hrzcm_ci.id OR r.target_ci_id = hrzcm_ci.id)
               AND r.relation_type = #{quoted}"
            ).distinct
          end
        end
        next
      end

      next unless valid_field?(field)

      case operator
      when '='  then scope = scope.where("#{field} = ?", value)
      when '!=' then scope = scope.where("#{field} != ?", value)
      when '~'  then scope = scope.where("#{field} LIKE ?", "%#{sanitize_like(value)}%")
      when '!~' then scope = scope.where("#{field} NOT LIKE ?", "%#{sanitize_like(value)}%")
      when '>=' then scope = scope.where("#{field} >= ?", value)
      when '<=' then scope = scope.where("#{field} <= ?", value)
      when '*'  then scope = scope.where.not(field => [nil, ''])
      when '!*' then scope = scope.where(field => [nil, ''])
      end
    end
    scope
  end

  def apply_sort(scope)
    col = sort_column.presence
    dir = sort_direction.to_s == 'desc' ? 'DESC' : 'ASC'
    valid_field?(col) ? scope.order("#{col} #{dir}") : scope.order('created_on DESC')
  end

  def valid_field?(field)
    all = (AVAILABLE_COLUMNS[entity_type] || []).map(&:first) + VIRTUAL_FIELDS + [RELATION_FILTER]
    all.include?(field.to_s)
  end

  def sanitize_like(str)
    str.gsub('%', '\\%').gsub('_', '\\_')
  end
end
