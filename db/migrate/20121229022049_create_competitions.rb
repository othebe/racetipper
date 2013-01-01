class CreateCompetitions < ActiveRecord::Migration
  def change
    create_table :competitions do |t|
      t.integer :creator_id
      t.string :name
      t.text :description
      t.string :image_url
      t.integer :season_id

      t.timestamps
    end
  end
end
