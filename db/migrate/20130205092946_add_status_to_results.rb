class AddStatusToResults < ActiveRecord::Migration
  def change
    add_column :results, :status, :integer, :default=>1
  end
end
