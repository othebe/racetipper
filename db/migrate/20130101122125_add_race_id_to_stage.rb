class AddRaceIdToStage < ActiveRecord::Migration
  def change
    add_column :stages, :race_id, :integer
  end
end
