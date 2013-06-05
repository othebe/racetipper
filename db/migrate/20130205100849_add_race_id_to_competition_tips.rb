class AddRaceIdToCompetitionTips < ActiveRecord::Migration
  def change
    add_column :competition_tips, :race_id, :integer
  end
end
