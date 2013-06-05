class AddPointsToResults < ActiveRecord::Migration
  def change
    add_column :results, :points, :float
  end
end
