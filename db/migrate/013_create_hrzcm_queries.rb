class CreateHrzcmQueries < ActiveRecord::Migration[6.1]
  def change
    create_table :hrzcm_queries do |t|
      t.string  :name,           limit: 255,  null: false
      t.text    :description,    limit: 2000
      t.integer :user_id,                     null: false
      t.boolean :is_public,      default: false, null: false
      t.string  :entity_type,    limit: 30,   null: false
      t.text    :filters,        limit: 10000
      t.text    :columns,        limit: 2000
      t.string  :sort_column,    limit: 60
      t.string  :sort_direction, limit: 4,    default: 'asc'
      t.integer :created_by
      t.integer :updated_by
      t.timestamp :created_on
      t.timestamp :updated_on
    end

    add_index :hrzcm_queries, :user_id
    add_index :hrzcm_queries, :entity_type
    add_index :hrzcm_queries, :is_public
  end
end
