class AddIndexToCompetitions < ActiveRecord::Migration
  def change
	add_index :competitions, :race_id, {:name=>'race_id_ndx_competitions'}
	add_index :competitions, :scope, {:name=>'scope_ndx_competitions'}
  end
end
