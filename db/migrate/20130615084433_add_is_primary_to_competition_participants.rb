class AddIsPrimaryToCompetitionParticipants < ActiveRecord::Migration
  def change
    add_column :competition_participants, :is_primary, :boolean, {:default=>false}
  end
end
