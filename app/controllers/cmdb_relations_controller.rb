class CmdbRelationsController < ApplicationController
  before_action :require_login
  before_action :check_permissions

  def index
    @ci_list     = HrzcmCi.ordered_by_abbr
    @selected_ci = params[:ci_id].present? ? HrzcmCi.find_by(id: params[:ci_id]) : nil
    @direction   = params[:direction] || 'down'
    @rel_types   = params[:rel_types].presence || HrzcmCiRelation::RELATION_TYPES
    @max_depth   = (params[:max_depth] || 8).to_i.clamp(1, 15)

    if @selected_ci
      @tree = build_tree(@selected_ci, @direction, Array(@rel_types), @max_depth, Set.new)
    end
  end

  def tree_data
    ci = HrzcmCi.find_by(id: params[:ci_id])
    render json: { error: 'Not found' }, status: 404 and return unless ci

    direction = params[:direction] || 'down'
    rel_types = params[:rel_types].present? ? Array(params[:rel_types]) : HrzcmCiRelation::RELATION_TYPES
    max_depth = (params[:max_depth] || 8).to_i.clamp(1, 15)

    tree = build_tree(ci, direction, rel_types, max_depth, Set.new)
    render json: tree
  end

  private

  def check_permissions
    unless User.current.logged? &&
           (HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'view_cmdb') ||
            HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'edit_cmdb') ||
            HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'edit_basic_data'))
      render plain: 'Forbidden', status: 403
    end
  end

  def build_tree(ci, direction, rel_types, depth, visited)
    node = {
      id:       ci.id,
      name:     ci.b_name_abbr || ci.b_name_full || "CI##{ci.id}",
      ci_class: ci.ci_class&.b_name_abbr || '',
      status:   ci.lifecycle_status&.b_key || '',
      children: []
    }
    return node if depth <= 0 || visited.include?(ci.id)
    visited = visited + [ci.id]

    if direction == 'down' || direction == 'both'
      ci.outgoing_relations.where(relation_type: rel_types).includes(:target_ci).each do |rel|
        next unless rel.target_ci
        child = build_tree(rel.target_ci, direction, rel_types, depth - 1, visited)
        child[:via] = rel.relation_type
        child[:direction_out] = true
        node[:children] << child
      end
    end

    if direction == 'up' || direction == 'both'
      ci.incoming_relations.where(relation_type: rel_types).includes(:source_ci).each do |rel|
        next unless rel.source_ci
        child = build_tree(rel.source_ci, direction, rel_types, depth - 1, visited)
        child[:via] = rel.relation_type
        child[:direction_in] = true
        node[:children] << child
      end
    end

    node
  end
end
