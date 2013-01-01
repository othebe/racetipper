class CreateResults < ActiveRecord::Migration
  def change
    create_table :results do |t|
      t.integer :season_stage_id
      t.integer :rider_id
      t.float :time
      t.float :kom_points
      t.float :sprint_points

      t.timestamps
    end
  end
end
