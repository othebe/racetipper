class CreateRaceTeams < ActiveRecord::Migration
  def change
    create_table :race_teams do |t|
      t.integer :team_id
      t.integer :race_id
      t.integer :status

      t.timestamps
    end
  end
end
