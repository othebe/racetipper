class AddDescriptionToArticleLinks < ActiveRecord::Migration
  def change
    add_column :article_links, :description, :string
  end
end
