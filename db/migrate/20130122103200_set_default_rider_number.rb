class SetDefaultRiderNumber < ActiveRecord::Migration
  def up
	change_column :team_riders, :rider_number, :integer, {:default=>0}
  end

  def down
  end
end
