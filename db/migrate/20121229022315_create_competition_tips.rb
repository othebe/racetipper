class CreateCompetitionTips < ActiveRecord::Migration
  def change
    create_table :competition_tips do |t|
      t.integer :competition_participant_id
      t.integer :season_stage_id
      t.integer :rider_id

      t.timestamps
    end
  end
end
