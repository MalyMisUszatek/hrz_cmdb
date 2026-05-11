#-------------------------------------------------------------------------------------eohdr-
# Purpose: CRUD for custom field definitions per CiClass.
#          Accessible only to edit_basic_data permission holders.
#-------------------------------------------------------------------------------------eohdr-
class HrzcmCustomFieldDefsController < ApplicationController
  before_action :require_login
  before_action :require_edit_permission
  before_action :load_ci_class
  before_action :load_field_def, only: [:edit, :update, :destroy, :move]

  def create
    @field_def = @ci_class.custom_field_defs.build(field_def_params)
    @field_def.j_sort = (@ci_class.custom_field_defs.maximum(:j_sort) || 0) + 10
    if @field_def.save
      respond_to do |fmt|
        fmt.html { redirect_to cmdb_index_path(anchor: "ci_class_#{@ci_class.id}"),
                                notice: l(:notice_successful_create) }
        fmt.js
      end
    else
      respond_to do |fmt|
        fmt.html { redirect_to cmdb_index_path(anchor: "ci_class_#{@ci_class.id}"),
                                alert: @field_def.errors.full_messages.join(', ') }
        fmt.js { render :error }
      end
    end
  end

  def update
    if @field_def.update(field_def_params)
      respond_to do |fmt|
        fmt.html { redirect_to cmdb_index_path(anchor: "ci_class_#{@ci_class.id}"),
                                notice: l(:notice_successful_update) }
        fmt.js
      end
    else
      respond_to do |fmt|
        fmt.html { redirect_to cmdb_index_path(anchor: "ci_class_#{@ci_class.id}"),
                                alert: @field_def.errors.full_messages.join(', ') }
        fmt.js { render :error }
      end
    end
  end

  def destroy
    @field_def.destroy
    respond_to do |fmt|
      fmt.html { redirect_to cmdb_index_path(anchor: "ci_class_#{@ci_class.id}"),
                              notice: l(:notice_successful_delete) }
      fmt.js
    end
  end

  # POST move — zmień kolejność (j_sort)
  def move
    direction = params[:direction]
    siblings  = @ci_class.custom_field_defs.to_a
    idx       = siblings.index(@field_def)
    if direction == 'up' && idx > 0
      siblings[idx].j_sort, siblings[idx-1].j_sort =
        siblings[idx-1].j_sort, siblings[idx].j_sort
      siblings[idx].save!
      siblings[idx-1].save!
    elsif direction == 'down' && idx < siblings.size - 1
      siblings[idx].j_sort, siblings[idx+1].j_sort =
        siblings[idx+1].j_sort, siblings[idx].j_sort
      siblings[idx].save!
      siblings[idx+1].save!
    end
    respond_to do |fmt|
      fmt.html { redirect_to cmdb_index_path(anchor: "ci_class_#{@ci_class.id}") }
      fmt.js
    end
  end

  private

  def require_edit_permission
    unless HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'edit_basic_data')
      render_403
    end
  end

  def load_ci_class
    @ci_class = HrzcmCiClass.find(params[:ci_class_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def load_field_def
    @field_def = @ci_class.custom_field_defs.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def field_def_params
    p = params.require(:field_def).permit(
      :b_name, :b_key, :field_type, :is_required,
      :default_value, :j_sort, :list_values
    )
    # list_values przychodzi jako textarea (jedna wartość na linię) -> JSON
    if p[:list_values].present?
      lines = p[:list_values].split(/\r?\n/).map(&:strip).reject(&:blank?)
      p[:list_values] = lines.to_json
    end
    p
  end
end
