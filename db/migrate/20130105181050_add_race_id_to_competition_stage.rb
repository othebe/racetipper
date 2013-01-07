class AddRaceIdToCompetitionStage < ActiveRecord::Migration
  def change
    add_column :competition_stages, :race_id, :integer
  end
end
