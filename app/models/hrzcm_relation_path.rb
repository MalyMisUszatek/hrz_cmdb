# Opcja B: dla kazdego CI z wybranej klasy generuje lancuchy relacji
class HrzcmRelationPath
  MAX_DEPTH = 6

  RELATION_TYPES = %w[connected_to contains installed_on runs_on virtualizes].freeze
  DIRECTIONS     = %w[out in both].freeze

  attr_reader :ci_class_id, :relation_types, :max_depth, :direction, :exclude_ci_ids

  def initialize(params = {})
    @ci_class_id    = params[:ci_class_id].presence
    @relation_types = Array(params[:relation_types]).reject(&:blank?)
    @max_depth      = [[params[:max_depth].to_i, 1].max, MAX_DEPTH].min
    @direction      = params[:direction].to_s.presence || 'out'
    @exclude_ci_ids = Array(params[:exclude_ci_ids]).map(&:to_i).reject(&:zero?).to_set
  end

  def run_as_strings
    starting_cis.flat_map do |ci|
      paths = traverse(ci, [], [], 0)
      paths.map do |path|
        path.map { |el| el.is_a?(HrzcmCi) ? (el.b_name_abbr.presence || el.b_name_full) : el.to_s }
      end
    end
  end

  # Zwraca liste wszystkich CI uzytych w wynikach (do podgladu wykluczonych)
  def all_ci_names
    starting_cis.flat_map do |ci|
      traverse(ci, [], [], 0).flat_map { |path| path.select { |el| el.is_a?(HrzcmCi) } }
    end.uniq(&:id).map { |ci| { id: ci.id, name: ci.b_name_abbr.presence || ci.b_name_full } }
  end

  private

  def starting_cis
    return [] unless @ci_class_id.present?
    HrzcmCi.where(j_ci_class_id: @ci_class_id).order(:b_name_abbr)
  end

  def next_steps(ci)
    steps = []
    if %w[out both].include?(@direction)
      rels = ci.outgoing_relations.includes(:target_ci)
      rels = rels.where(relation_type: @relation_types) if @relation_types.any?
      rels.each { |r| steps << [r.relation_type, r.target_ci] if r.target_ci }
    end
    if %w[in both].include?(@direction)
      rels = ci.incoming_relations.includes(:source_ci)
      rels = rels.where(relation_type: @relation_types) if @relation_types.any?
      rels.each { |r| steps << [r.relation_type, r.source_ci] if r.source_ci }
    end
    steps
  end

  def traverse(ci, current_path, visited_ids, depth)
    current_path = current_path + [ci]
    visited_ids  = visited_ids + [ci.id]
    steps = next_steps(ci)
      .reject { |_rel, next_ci| visited_ids.include?(next_ci.id) }
      .reject { |_rel, next_ci| @exclude_ci_ids.include?(next_ci.id) }
    return [current_path] if steps.empty? || depth >= @max_depth
    steps.flat_map do |rel_type, next_ci|
      traverse(next_ci, current_path + [rel_type], visited_ids, depth + 1)
    end
  end
end
