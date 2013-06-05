class AddStatusToDefaultRiders < ActiveRecord::Migration
  def change
    add_column :default_riders, :status, :integer, :default=>1
  end
end
