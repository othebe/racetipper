class CreateRiders < ActiveRecord::Migration
  def change
    create_table :riders do |t|
      t.string :name
      t.string :photo_url

      t.timestamps
    end
  end
end
