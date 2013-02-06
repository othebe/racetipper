class AddRiderStatusToTeamRiders < ActiveRecord::Migration
  def change
    add_column :team_riders, :rider_status, :integer, :default=>1
  end
end
