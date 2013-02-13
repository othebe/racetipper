class RemoveRaceIdFromTeams < ActiveRecord::Migration
  def up
	remove_column :teams, :race_id
  end

  def down
	add_column :teams, race_id, :integer
  end
end
