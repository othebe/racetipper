class AddStatusToCompetitionTips < ActiveRecord::Migration
  def change
    add_column :competition_tips, :status, :integer, :default=>1
  end
end
