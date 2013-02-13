class AddRaceIdToTeamRiders < ActiveRecord::Migration
  def change
    add_column :team_riders, :race_id, :integer
  end
end
