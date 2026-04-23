class HrzcmCiRelation < ActiveRecord::Base
  self.table_name = 'hrzcm_ci_relations'

  RELATION_TYPES = %w[
    runs_on
    depends_on
    contains
    connected_to
    installed_on
    virtualizes
    backs_up
  ].freeze

  belongs_to :source_ci, class_name: 'HrzcmCi', foreign_key: 'source_ci_id'
  belongs_to :target_ci, class_name: 'HrzcmCi', foreign_key: 'target_ci_id'
  belongs_to :creator, class_name: 'User', foreign_key: 'created_by', optional: true

  validates :source_ci_id, presence: true
  validates :target_ci_id, presence: true
  validates :relation_type, presence: true, inclusion: { in: RELATION_TYPES }
  validates :b_comment, length: { maximum: 1000 }
  validate :source_and_target_must_differ
  validates :source_ci_id, uniqueness: { scope: [:target_ci_id, :relation_type],
            message: :relation_already_exists }

  before_create :set_creator

  scope :for_ci, ->(ci_id) {
    where('source_ci_id = ? OR target_ci_id = ?', ci_id, ci_id)
  }

  def inverse_type
    case relation_type
    when 'runs_on'      then 'has_running'
    when 'depends_on'   then 'is_dependency_of'
    when 'contains'     then 'is_contained_in'
    when 'connected_to' then 'connected_to'
    when 'installed_on' then 'has_installed'
    when 'virtualizes'  then 'is_virtualized_by'
    when 'backs_up'     then 'is_backed_up_by'
    end
  end

  private

  def source_and_target_must_differ
    if source_ci_id.present? && target_ci_id.present? && source_ci_id == target_ci_id
      errors.add(:target_ci_id, :cannot_relate_to_itself)
    end
  end

  def set_creator
    self.created_by ||= User.current&.id
    self.created_on ||= Time.current
  end
end
