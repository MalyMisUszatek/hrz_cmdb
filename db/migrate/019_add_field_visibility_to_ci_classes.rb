class AddFieldVisibilityToCiClasses < ActiveRecord::Migration[7.2]
  # Sprawdź prawdziwą nazwę tabeli w bazie: bundle exec rails runner 'puts ActiveRecord::Base.connection.tables.grep(/ci/).sort.inspect'
  TABLE = :hrzcm_ci_classes  # <-- zmień jeśli inna nazwa

  def up
    return unless table_exists?(TABLE)
    %i[show_bproducer show_bmodel show_btagserial show_burldoc].each do |col|
      add_column TABLE, col, :boolean, null: false, default: true unless
        column_exists?(TABLE, col)
    end
  end

  def down
    return unless table_exists?(TABLE)
    %i[show_bproducer show_bmodel show_btagserial show_burldoc].each do |col|
      remove_column TABLE, col if column_exists?(TABLE, col)
    end
  end
end
