class AddUrlTypeToArticleLinks < ActiveRecord::Migration
  def change
    add_column :article_links, :url_type, :integer, :default=>1
  end
end
