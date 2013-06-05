class AddBonusTimeToResults < ActiveRecord::Migration
  def change
    add_column :results, :bonus_time, :integer, :default=>0
  end
end
