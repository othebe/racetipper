class AddCompetitionTypeToCompetitions < ActiveRecord::Migration
  def change
    add_column :competitions, :competition_type, :integer, :default=>1
  end
end
