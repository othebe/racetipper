class AddRiderStatusToResults < ActiveRecord::Migration
  def change
    add_column :results, :rider_status, :integer, :default=>1
  end
end
