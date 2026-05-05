class CmdbCiHistoryController < ApplicationController
  include CmdbHelper
  before_action :require_login
  before_action :check_view_permission
  before_action :find_ci

  UPLOAD_PATH = File.join(Rails.root, 'plugins', 'hrz_cmdb', 'files')

  def index
    @audit_logs  = HrzcmCiAudit.for_ci(@ci.id)
    @attachments = HrzcmCiAttachment.for_ci(@ci.id)
  end

  def create_attachment
    file = params[:file]
    if file.blank?
      redirect_to "/cmdb/ci/#{@ci.id}", alert: 'Nie wybrano pliku' and return
    end
    ext       = File.extname(file.original_filename).downcase
    disk_fname = "ci_#{@ci.id}_#{Time.now.to_i}#{ext}"
    FileUtils.mkdir_p(UPLOAD_PATH)
    File.open(File.join(UPLOAD_PATH, disk_fname), 'wb') { |f| f.write(file.read) }
    HrzcmCiAttachment.create!(
      ci_id: @ci.id, user_id: User.current.id,
      filename: file.original_filename,
      description: params[:description].to_s.strip[0, 512],
      content_type: file.content_type, filesize: file.size,
      disk_filename: disk_fname, created_at: Time.now
    )
    HrzcmCiAudit.log(@ci, action: 'attachment_added',
      note: "Dodano plik: #{file.original_filename}")
    redirect_to "/cmdb/ci/#{@ci.id}",
      notice: "Plik '#{file.original_filename}' dodany pomyślnie"
  end

  def destroy_attachment
    att = HrzcmCiAttachment.find(params[:att_id])
    File.delete(att.disk_path) if File.exist?(att.disk_path)
    HrzcmCiAudit.log(@ci, action: 'attachment_removed', note: "Usunięto plik: #{att.filename}")
    att.destroy
    redirect_to "/cmdb/ci/#{@ci.id}", notice: 'Plik usunięty'
  end

  def download_attachment
    att = HrzcmCiAttachment.find(params[:att_id])
    send_file att.disk_path,
      filename: att.filename,
      type: att.content_type || 'application/octet-stream',
      disposition: 'attachment'
  end

  private

  def find_ci
    @ci = HrzcmCi.find(params[:ci_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def check_view_permission
    deny_access unless HrzCmdb::PermissionHelper.user_has_permission?(User.current, 'view_cmdb')
  end
end
