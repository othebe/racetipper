class RenameStageIdToCompetitionTips < ActiveRecord::Migration
  def change
    rename_column :competition_tips, :season_stage_id, :stage_id
  end
end
