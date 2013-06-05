class AddRaceIdToCompetitions < ActiveRecord::Migration
  def change
    add_column :competitions, :race_id, :integer
  end
end
