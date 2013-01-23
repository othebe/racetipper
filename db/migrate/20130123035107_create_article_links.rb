class CreateArticleLinks < ActiveRecord::Migration
  def change
    create_table :article_links do |t|
      t.integer :article_id
      t.string :url

      t.timestamps
    end
  end
end
