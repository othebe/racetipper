class AddStatusToRider < ActiveRecord::Migration
  def change
    add_column :riders, :status, :integer, :default=>1
	add_column :stages, :status, :integer, :default=>1
	add_column :races, :status, :integer, :default=>1
	add_column :season_stages, :status, :integer, :default=>1
	add_column :competitions, :status, :integer, :default=>1
	add_column :competition_stages, :status, :integer, :default=>1
	add_column :competition_participants, :status, :integer, :default=>1
	add_column :teams, :status, :integer, :default=>1
	add_column :team_riders, :status, :integer, :default=>1
	add_column :race_stages, :status, :integer, :default=>1
  end
end
