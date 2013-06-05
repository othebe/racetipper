class AddRaceIdToTeams < ActiveRecord::Migration
  def change
    add_column :teams, :race_id, :integer
  end
end
