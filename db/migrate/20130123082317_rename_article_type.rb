class RenameArticleType < ActiveRecord::Migration
  def up
	rename_column :articles, :type, :article_type
  end

  def down
	rename_column :articles, :article_type, :article
  end
end
