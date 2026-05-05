#-------------------------------------------------------------------------------------------#
# Redmine CMDB plugin - CmdbHelper                                                          #
# Copyright (C) 2025 Franz Apeltauer - GNU AGPLv3                                           #
#-------------------------------------------------------------------------------------------#
module CmdbHelper
  def can_view_cmdb?
    HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'view_cmdb') ||
    HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'edit_cmdb') ||
    HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'edit_basic_data')
  end

  def can_edit_cmdb?
    HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'edit_cmdb')
  end

  def can_edit_basic_data?
    HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'edit_basic_data')
  end

  def format_documentation_link(documentation)
    return '' if documentation.blank?
    if documentation.starts_with?('tiki:')
      page_name = documentation.sub('tiki:', '')
      link_to documentation, "#", onclick: "HrzCmdb.openTiki('#{page_name}'); return false;",
              class: 'documentation-link', target: '_blank'
    elsif documentation =~ /\Ahttps?:\/\//
      link_to documentation, documentation, class: 'documentation-link', target: '_blank'
    else
      content_tag :span, documentation, class: 'documentation-text'
    end
  end

  def location_breadcrumb(location)
    parts = []
    current = location
    while current
      parts.unshift(link_to(current.b_name_abbr || current.b_name_full,
                           "#", onclick: "HrzCmdb.loadLocation(#{current.id}); return false;"))
      current = current.parent1
    end
    safe_join(parts, ' > ')
  end

  def render_location_tree_options(selected_id = nil, exclude_id = nil)
    options = []
    HrzcmLocatHier.ordered_by_level.each do |hierarchy|
      options << content_tag(:optgroup, label: hierarchy.b_name_abbr) do
        locations = HrzcmLocation.for_type(hierarchy.id).ordered_by_b_name_abbr
        locations = locations.where.not(id: exclude_id) if exclude_id
        options_from_collection_for_select(locations, :id, :display_name, selected_id)
      end
    end
    safe_join(options)
  end

  def cmdb_icon(type)
    case type
    when 'folder', 'location_with_children' then content_tag(:span, '📁', class: 'icon icon-folder')
    when 'page',   'location'               then content_tag(:span, '📄', class: 'icon icon-page')
    when 'add',    'new'                    then content_tag(:span, '➕', class: 'icon icon-add')
    else                                         content_tag(:span, '▪',  class: 'icon icon-default')
    end
  end

  def cmdb_javascript_translations
    translations = {
      select_item:    l('hrz_cmdb.select_item'),
      save:           l('hrz_cmdb.buttons.save'),
      cancel:         l('hrz_cmdb.buttons.cancel'),
      create:         l('hrz_cmdb.buttons.create'),
      confirm_delete: l(:text_are_you_sure)
    }
    javascript_tag "window.hrz_cmdb_translations = #{translations.to_json};"
  end

  def format_query_result_value(record, column)
    case column
    when 'relations_out'
      rels = HrzcmCiRelation.where(source_ci_id: record.id)
                            .includes(:target_ci).order(:relation_type)
      return '&mdash;'.html_safe if rels.empty?
      safe_join(rels.map { |r|
        tgt = r.target_ci&.b_name_abbr || r.target_ci&.b_name_full || "CI##{r.target_ci_id}"
        content_tag(:span, class: 'cmdb-rel-badge') {
          content_tag(:span, I18n.t("hrz_cmdb.ci_relations.types.#{r.relation_type}", default: r.relation_type), class: 'cmdb-rel-type') +
          ' &rarr; '.html_safe +
          content_tag(:span, tgt, class: 'cmdb-rel-target')
        }
      }, ' '.html_safe)
    when 'relations_in'
      rels = HrzcmCiRelation.where(target_ci_id: record.id)
                            .includes(:source_ci).order(:relation_type)
      return '&mdash;'.html_safe if rels.empty?
      safe_join(rels.map { |r|
        src = r.source_ci&.b_name_abbr || r.source_ci&.b_name_full || "CI##{r.source_ci_id}"
        content_tag(:span, class: 'cmdb-rel-badge') {
          content_tag(:span, src, class: 'cmdb-rel-target') +
          ' &rarr; '.html_safe +
          content_tag(:span, I18n.t("hrz_cmdb.ci_relations.types.#{r.relation_type}", default: r.relation_type), class: 'cmdb-rel-type')
        }
      }, ' '.html_safe)
    when 'j_ci_class_id'    then HrzcmCiClass.find_by(id: record.try(:j_ci_class_id))&.b_name_full.to_s
    when 'j_location_id'    then HrzcmLocation.find_by(id: record.try(:j_location_id))&.b_name_full.to_s
    when 'j_status_id'      then HrzcmLifecycleStatus.find_by(id: record.try(:j_status_id))&.b_name_full.to_s
    when 'j_type_id'        then HrzcmLocatHier.find_by(id: record.try(:j_type_id))&.b_name_abbr.to_s
    when 'j_part_of1_id'    then HrzcmLocation.find_by(id: record.try(:j_part_of1_id))&.b_name_full.to_s
    when 'j_subclass_of_id' then HrzcmCiClass.find_by(id: record.try(:j_subclass_of_id))&.b_name_full.to_s
    when 'created_on', 'updated_on'
      record.try(column)&.strftime('%Y-%m-%d %H:%M').to_s
    else
      record.try(column).to_s
    end
  end
end
