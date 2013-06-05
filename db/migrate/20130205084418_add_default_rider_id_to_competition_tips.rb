class AddDefaultRiderIdToCompetitionTips < ActiveRecord::Migration
  def change
    add_column :competition_tips, :default_rider_id, :integer
  end
end
