class AddCompetitionIdToCompetitionTips < ActiveRecord::Migration
  def change
    add_column :competition_tips, :competition_id, :integer
  end
end
