class CreateMetadata < ActiveRecord::Migration
  def change
    create_table :metadata do |t|
      t.string :object_type
      t.integer :object_id
      t.string :title
      t.string :data_type
      t.text :data

      t.timestamps
    end
  end
end
