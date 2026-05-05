class HrzcmCiAudit < ActiveRecord::Base
  self.table_name = :hrzcm_ci_audit

  belongs_to :ci,   class_name: 'HrzcmCi', foreign_key: :ci_id
  belongs_to :user, class_name: 'User',     foreign_key: :user_id, optional: true

  scope :for_ci, ->(ci_id) { where(ci_id: ci_id).order(created_at: :desc) }

  def self.log(ci, action:, field: nil, old_val: nil, new_val: nil, note: nil, user: nil)
    return if action == 'update' && old_val.to_s == new_val.to_s
    create!(
      ci_id:      ci.id,
      user_id:    (user || User.current)&.id,
      action:     action,
      field_name: field,
      old_value:  old_val.to_s.presence,
      new_value:  new_val.to_s.presence,
      note:       note,
      created_at: Time.now
    )
  end
end
