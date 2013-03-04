class AddRankToResults < ActiveRecord::Migration
  def change
    add_column :results, :rank, :integer, :default=>0
  end
end
