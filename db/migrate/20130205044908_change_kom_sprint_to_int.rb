class ChangeKomSprintToInt < ActiveRecord::Migration
  def up
	change_column :results, :kom_points, :integer, :default=>0
	change_column :results, :sprint_points, :integer, :default=>0
  end

  def down
	change_column :results, :kom_points, :float, :default=>0
	change_column :results, :sprint_points, :float, :default=>0
  end
end
