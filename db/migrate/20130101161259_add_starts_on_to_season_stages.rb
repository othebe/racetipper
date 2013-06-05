class AddStartsOnToSeasonStages < ActiveRecord::Migration
  def change
    add_column :season_stages, :starts_on, :string
  end
end
