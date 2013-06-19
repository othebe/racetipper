class AddScopeToCompetitions < ActiveRecord::Migration
  def change
    add_column :competitions, :scope, :integer, {:default=>0}
  end
end
