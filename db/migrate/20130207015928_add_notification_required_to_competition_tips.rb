class AddNotificationRequiredToCompetitionTips < ActiveRecord::Migration
  def change
    add_column :competition_tips, :notification_required, :boolean, :default=>false
  end
end
