class AddStatusToSeason < ActiveRecord::Migration
  def change
    add_column :seasons, :status, :integer, :default=>2
  end
end
