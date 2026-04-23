class CiRelationsController < ApplicationController
  before_action :find_ci
  before_action :check_view_permission
  before_action :find_relation, only: [:destroy]
  before_action :check_edit_permission, only: [:create, :destroy]

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
