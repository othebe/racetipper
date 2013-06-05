class CreateTeamRiders < ActiveRecord::Migration
  def change
    create_table :team_riders do |t|
      t.integer :team_id
      t.integer :rider_id
      t.string :display_name

      t.timestamps
    end
  end
end
