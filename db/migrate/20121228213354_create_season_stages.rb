class CreateSeasonStages < ActiveRecord::Migration
  def change
    create_table :season_stages do |t|
      t.integer :season_id
      t.integer :race_id
      t.integer :stage_id
      t.datetime :start_dt
      t.datetime :end_dt

      t.timestamps
    end
  end
end
