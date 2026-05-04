require 'csv'

class CmdbQueriesController < ApplicationController
  include CmdbHelper

  before_action :require_login
  before_action :check_view_permission
  before_action :find_query, only: [:show, :edit, :update, :destroy, :results]

  def index
    @public_queries = HrzcmQuery.where(is_public: true).order(:name)
    @my_queries     = HrzcmQuery.where(user_id: User.current.id, is_public: false).order(:name)

    if params[:query_id].present?
      begin
        @active_query = HrzcmQuery.find(params[:query_id])
        unless @active_query.is_public? || @active_query.user_id == User.current.id || User.current.admin?
          @active_query = nil
        end
      rescue ActiveRecord::RecordNotFound
        @active_query = nil
      end
    else
      @active_query = HrzcmQuery.find_by(is_public: true, name: 'Wszystkie elementy CMDB') ||
                      @public_queries.first
    end

    load_query_results if @active_query
  end

  def new
    @query = HrzcmQuery.new(entity_type: params[:entity_type] || 'ci', sort_direction: 'asc')
  end

  def create
    @query = HrzcmQuery.new(query_params)
    @query.user_id = @query.created_by = @query.updated_by = User.current.id

    if @query.save
      flash[:notice] = l('hrz_cmdb.queries.created')
      redirect_to results_cmdb_query_path(@query)
    else
      render :new
    end
  end

  def show
    redirect_to results_cmdb_query_path(@query)
  end

  def edit
  end

  def update
    @query.updated_by = User.current.id
    if @query.update(query_params)
      flash[:notice] = l('hrz_cmdb.queries.updated')
      redirect_to results_cmdb_query_path(@query)
    else
      render :edit
    end
  end

  def destroy
    @query.destroy
    flash[:notice] = l('hrz_cmdb.queries.deleted')
    redirect_to cmdb_queries_path
  end

  def results
    @per_page    = per_page_option
    scope        = @query.results_scope
    @entry_count = scope.count
    @entry_pages = Redmine::Pagination::Paginator.new(@entry_count, @per_page, params[:page])
    @entries     = scope.offset(@entry_pages.offset).limit(@per_page)

    respond_to do |format|
      format.html
      format.csv { send_query_csv(scope) }
    end
  end


  def load_query_results
    @per_page    = per_page_option
    scope        = @active_query.results_scope
    @entry_count = scope.count
    @entry_pages = Redmine::Pagination::Paginator.new(@entry_count, @per_page, params[:page])
    @entries     = scope.offset(@entry_pages.offset).limit(@per_page)
  end

  private

  def find_query
    @query = HrzcmQuery.find(params[:id])
    unless @query.is_public? || @query.user_id == User.current.id || User.current.admin?
      deny_access
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def query_params
    params.require(:hrzcm_query).permit(
      :name, :description, :is_public, :entity_type,
      :sort_column, :sort_direction, :filters, :columns
    )
  end

  def check_view_permission
    deny_access unless can_view_cmdb?
  end

  def send_query_csv(scope)
    cols = @query.columns_data

    csv_str = CSV.generate(encoding: 'UTF-8') do |csv|
      csv << cols.map { |c| l("hrz_cmdb.fields.#{c}", default: c) }
      scope.each do |rec|
        csv << cols.map { |c| format_query_cell(rec, c) }
      end
    end

    send_data "\xEF\xBB\xBF" + csv_str,
      filename: "cmdb_#{@query.entity_type}_#{Date.today}.csv",
      type: 'text/csv; charset=utf-8',
      disposition: 'attachment'
  end

  def format_query_cell(record, column)
    val = record.respond_to?(column) ? record.send(column) : nil
    case column
    when 'j_ci_class_id'    then HrzcmCiClass.find_by(id: val)&.b_name_full.to_s
    when 'j_location_id'    then HrzcmLocation.find_by(id: val)&.b_name_full.to_s
    when 'j_status_id'      then HrzcmLifecycleStatus.find_by(id: val)&.b_name_full.to_s
    when 'j_type_id'        then HrzcmLocatHier.find_by(id: val)&.b_name_abbr.to_s
    when 'j_part_of1_id'    then HrzcmLocation.find_by(id: val)&.b_name_full.to_s
    when 'j_subclass_of_id' then HrzcmCiClass.find_by(id: val)&.b_name_full.to_s
    when 'created_on', 'updated_on' then val&.strftime('%Y-%m-%d %H:%M').to_s
    else val.to_s
    end
  end
end
