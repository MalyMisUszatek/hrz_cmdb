class CreateHrzcmCiRelations < ActiveRecord::Migration[6.1]
  def change
    create_table :hrzcm_ci_relations do |t|
      t.bigint :source_ci_id, null: false
      t.bigint :target_ci_id, null: false
      t.string :relation_type, limit: 50, null: false
      t.text   :b_comment, limit: 1000
      t.integer :created_by
      t.timestamp :created_on
    end

    add_foreign_key :hrzcm_ci_relations, :hrzcm_ci, column: :source_ci_id
    add_foreign_key :hrzcm_ci_relations, :hrzcm_ci, column: :target_ci_id

    add_index :hrzcm_ci_relations, :source_ci_id
    add_index :hrzcm_ci_relations, :target_ci_id
    add_index :hrzcm_ci_relations, :relation_type
    add_index :hrzcm_ci_relations, [:source_ci_id, :target_ci_id, :relation_type],
              unique: true, name: 'idx_hrzcm_ci_relation_unique'
  end
end
