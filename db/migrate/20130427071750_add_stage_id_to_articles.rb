class AddStageIdToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :stage_id, :integer
  end
end
