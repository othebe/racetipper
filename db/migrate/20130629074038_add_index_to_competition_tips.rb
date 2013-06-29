class AddIndexToCompetitionTips < ActiveRecord::Migration
  def change
	add_index :competition_tips, :competition_id, {:name=>'competition_id_ndx_competition_tips'}
	add_index :competition_tips, :race_id, {:name=>'race_id_ndx_competition_tips'}
	add_index :competition_tips, :stage_id, {:name=>'stage_id_ndx_competition_tips'}
	add_index :competition_tips, :competition_participant_id, {:name=>'competition_participant_id_ndx_competition_tips'}
  end
end
