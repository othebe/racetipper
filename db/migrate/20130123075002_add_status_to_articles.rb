class AddStatusToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :status, :integer, :default=>1
  end
end
