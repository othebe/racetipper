class DropRaceStages < ActiveRecord::Migration
  def up
	drop_table :race_stages
	drop_table :season_stages
  end

  def down
	create_table :season_stages do |t|
      t.integer :season_id
      t.integer :race_id
      t.integer :stage_id
      t.datetime :start_dt
      t.datetime :end_dt

      t.timestamps
    end
	
	create_table :race_stages do |t|
      t.integer :race_id
      t.integer :stage_id

      t.timestamps
    end
  end
end
