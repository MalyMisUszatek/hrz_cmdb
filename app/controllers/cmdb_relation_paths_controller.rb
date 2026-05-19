require 'csv'

class CmdbRelationPathsController < ApplicationController
  include CmdbHelper
  before_action :require_login
  before_action :check_view_permission

  def index
    @ci_classes     = HrzcmCiClass.order(:b_name_full)
    @relation_types = HrzcmRelationPath::RELATION_TYPES
    @path_query     = HrzcmRelationPath.new(max_depth: 3, direction: 'out')
    @paths          = []
    @excluded_cis   = []
    @ran            = false
  end

  def run
    @ci_classes     = HrzcmCiClass.order(:b_name_full)
    @relation_types = HrzcmRelationPath::RELATION_TYPES
    @path_query     = HrzcmRelationPath.new(path_params)
    @paths          = @path_query.run_as_strings
    @excluded_cis   = excluded_ci_list
    @ran            = true
    respond_to do |format|
      format.html { render :index }
      format.csv  { send_path_csv }
    end
  end

  private

  def path_params
    p = params.permit(:ci_class_id, :max_depth, :direction,
                      relation_types: [], exclude_ci_ids: [])
    p[:relation_types]  = Array(p[:relation_types]).reject(&:blank?)
    p[:exclude_ci_ids]  = Array(p[:exclude_ci_ids]).reject(&:blank?)
    p
  end

  def excluded_ci_list
    ids = Array(params[:exclude_ci_ids]).reject(&:blank?).map(&:to_i)
    return [] if ids.empty?
    HrzcmCi.where(id: ids).map { |ci| { id: ci.id, name: ci.b_name_abbr.presence || ci.b_name_full } }
  end

  def ci_search
    q = params[:q].to_s.strip
    return render(json: []) if q.length < 2
    cis = HrzcmCi.where('b_name_abbr LIKE ? OR b_name_full LIKE ?',
                         "%#{q}%", "%#{q}%").limit(15)
    render json: cis.map { |ci|
      { value: ci.id, label: ci.b_name_abbr.presence || ci.b_name_full }
    }
  end

  def check_view_permission
    deny_access unless can_view_cmdb?
  end

  def send_path_csv
    max_len = @paths.map(&:length).max || 0
    headers_row = (0..max_len - 1).map do |i|
      i.even? ? "CI_#{i/2 + 1}" : "relacja_#{i/2 + 1}"
    end
    csv_str = CSV.generate(encoding: 'UTF-8') do |csv|
      csv << headers_row
      @paths.each { |path| csv << path }
    end
    send_data "\xEF\xBB\xBF" + csv_str,
      filename: "cmdb_lancuch_relacji_#{Date.today}.csv",
      type: 'text/csv; charset=utf-8',
      disposition: 'attachment'
  end
end
