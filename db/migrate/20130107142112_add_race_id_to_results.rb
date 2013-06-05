class AddRaceIdToResults < ActiveRecord::Migration
  def change
    add_column :results, :race_id, :integer
  end
end
