class SetDefaultStatusInTeamRiders < ActiveRecord::Migration
  def up
	change_column :race_teams, :status, :integer, {:default=>1}
  end

  def down
  end
end
