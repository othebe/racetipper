class AddRiderNumberToTeamRider < ActiveRecord::Migration
  def change
    add_column :team_riders, :rider_number, :integer
  end
end
