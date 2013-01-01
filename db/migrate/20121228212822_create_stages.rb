class CreateStages < ActiveRecord::Migration
  def change
    create_table :stages do |t|
      t.string :name
      t.text :description
      t.string :image_url
      t.text :profile

      t.timestamps
    end
  end
end
