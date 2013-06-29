class AddIndexToCompetitionParticipants < ActiveRecord::Migration
  def change
	add_index :competition_participants, :competition_id, {:name=>'competition_id_ndx_competition_participants'}
	add_index :competition_participants, :user_id, {:name=>'user_id_ndx_competition_participants'}
  end
end
