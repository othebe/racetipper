class CreateCompetitionParticipants < ActiveRecord::Migration
  def change
    create_table :competition_participants do |t|
      t.integer :competition_id
      t.integer :user_id

      t.timestamps
    end
  end
end
