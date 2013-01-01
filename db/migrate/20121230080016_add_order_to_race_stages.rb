class AddOrderToRaceStages < ActiveRecord::Migration
  def change
    add_column :race_stages, :order, :integer
  end
end
