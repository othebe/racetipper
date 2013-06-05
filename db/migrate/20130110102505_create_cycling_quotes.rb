class CreateCyclingQuotes < ActiveRecord::Migration
  def change
    create_table :cycling_quotes do |t|
      t.text :quote
      t.string :author

      t.timestamps
    end
  end
end
