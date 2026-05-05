class HrzcmCiAttachment < ActiveRecord::Base
  self.table_name = :hrzcm_ci_attachments

  belongs_to :ci,   class_name: 'HrzcmCi', foreign_key: :ci_id
  belongs_to :user, class_name: 'User',     foreign_key: :user_id, optional: true

  validates :filename,      presence: true
  validates :disk_filename, presence: true
  validates :ci_id,         presence: true

  UPLOAD_PATH = File.join(Rails.root, 'plugins', 'hrz_cmdb', 'files').freeze

  scope :for_ci, ->(ci_id) { where(ci_id: ci_id).order(created_at: :desc) }

  def disk_path
    File.join(UPLOAD_PATH, disk_filename)
  end

  def human_filesize
    return '-' unless filesize.to_i > 0
    kb = filesize.to_f / 1024
    kb < 1024 ? "#{'%.1f' % kb} KB" : "#{'%.1f' % (kb/1024)} MB"
  end
end
