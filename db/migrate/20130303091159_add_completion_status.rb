class AddCompletionStatus < ActiveRecord::Migration
  def up
	add_column :competitions, :is_complete, :boolean, :default=>false
	add_column :races, :is_complete, :boolean, :default=>false
	add_column :stages, :is_complete, :boolean, :default=>false
  end

  def down
  end
end
