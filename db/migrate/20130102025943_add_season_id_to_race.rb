class AddSeasonIdToRace < ActiveRecord::Migration
  def change
    add_column :races, :season_id, :integer
	add_column :stages, :order_id, :integer
	add_column :stages, :season_id, :integer
	add_column :stages, :starts_on, :datetime
	add_column :stages, :start_location, :string
	add_column :stages, :end_location, :string
	add_column :stages, :distance_km, :float
  end
end
