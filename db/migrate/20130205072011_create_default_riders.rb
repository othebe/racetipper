class CreateDefaultRiders < ActiveRecord::Migration
  def change
    create_table :default_riders do |t|
      t.integer :season_id
      t.integer :race_id
      t.integer :rider_id
      t.integer :order_id

      t.timestamps
    end
  end
end
