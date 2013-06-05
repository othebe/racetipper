class ChangeFbIdToBig < ActiveRecord::Migration
  def up
	change_column :users, :fb_id, :integer, :limit=>8
  end

  def down
  end
end
