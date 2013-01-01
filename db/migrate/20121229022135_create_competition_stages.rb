class CreateCompetitionStages < ActiveRecord::Migration
  def change
    create_table :competition_stages do |t|
      t.integer :competition_id
      t.integer :stage_id

      t.timestamps
    end
  end
end
