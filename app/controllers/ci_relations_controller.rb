class CiRelationsController < ApplicationController
  before_action :find_ci
  before_action :check_view_permission
  before_action :find_relation, only: [:destroy]
  before_action :check_edit_permission, only: [:create, :destroy, :replace]

  def index
    @relations = @ci.all_relations
    render partial: 'ci_relations/ci_relations_section',
           locals: { ci: @ci, relations: @relations, can_edit: can_edit? }
  end

  def create
    @relation = HrzcmCiRelation.new(relation_params)
    @relation.source_ci_id = @ci.id
    if @relation.save
      if request.xhr? || request.format.json?
        render json: { success: true, notice: I18n.t('hrz_cmdb.ci_relations.created') }
      else
        flash[:notice] = I18n.t('hrz_cmdb.ci_relations.created')
        redirect_to "/cmdb/ci/#{@ci.id}"
      end
    else
      if request.xhr? || request.format.json?
        render json: { success: false, errors: @relation.errors.full_messages }
      else
        flash[:error] = @relation.errors.full_messages.join(', ')
        redirect_to "/cmdb/ci/#{@ci.id}"
      end
    end
  end

  def destroy
    if @relation.destroy
      if request.xhr? || request.format.json?
        render json: { success: true, notice: I18n.t('hrz_cmdb.ci_relations.deleted') }
      else
        flash[:notice] = I18n.t('hrz_cmdb.ci_relations.deleted')
        redirect_to "/cmdb/ci/#{@ci.id}"
      end
    else
      if request.xhr? || request.format.json?
        render json: { success: false, errors: @relation.errors.full_messages }
      else
        flash[:error] = @relation.errors.full_messages.join(', ')
        redirect_to "/cmdb/ci/#{@ci.id}"
      end
    end
  end

  def replace
    new_ci_id = params[:new_ci_id].to_i
  
    unless new_ci_id > 0
      return render json: { success: false, errors: ['Nie wybrano nowego CI'] }
    end
  
    new_ci = HrzcmCi.find_by(id: new_ci_id)
    unless new_ci
      return render json: { success: false, errors: ['Nowe CI nie istnieje'] }
    end
  
    ActiveRecord::Base.transaction do
      HrzcmCiRelation.where(source_ci_id: @ci.id).update_all(source_ci_id: new_ci_id)
      HrzcmCiRelation.where(target_ci_id: @ci.id).update_all(target_ci_id: new_ci_id)
      HrzcmCiRelation.where(source_ci_id: new_ci_id)
                       .where(target_ci_id: new_ci_id).destroy_all
      end
  
    if params[:retire_old] == '1'
      retired_status = HrzcmLifecycleStatus.find_by(b_key: 'retired')
      @ci.update(j_status_id: retired_status.id) if retired_status
    end

    if request.xhr? || request.format.json?
     render json: { 
       success: true, 
       notice: I18n.t('hrz_cmdb.ci_relations.replaced'),
       redirect_ci_id: new_ci_id
     }
    else
      flash[:notice] = I18n.t('hrz_cmdb.ci_relations.replaced')
      redirect_to "/cmdb#ci_#{new_ci_id}"
    end  

  end
  private

  def find_ci
    @ci = HrzcmCi.find(params[:ci_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_relation
    @relation = HrzcmCiRelation.find(params[:id])
    unless @relation.source_ci_id == @ci.id || @relation.target_ci_id == @ci.id
      deny_access
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def check_view_permission
    deny_access unless HrzCmdb::PermissionHelper.can_view?(User.current)
  end

  def check_edit_permission
    deny_access unless HrzCmdb::PermissionHelper.can_edit?(User.current)
  end

  def can_edit?
    HrzCmdb::PermissionHelper.can_edit?(User.current)
  end

  def relation_params
    params.require(:ci_relation).permit(:target_ci_id, :relation_type, :b_comment)
  end
end
