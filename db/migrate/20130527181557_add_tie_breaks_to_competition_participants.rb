class AddTieBreaksToCompetitionParticipants < ActiveRecord::Migration
  def change
    add_column :competition_participants, :tie_break_rider_id, :integer
    add_column :competition_participants, :tie_break_time, :integer
  end
end
