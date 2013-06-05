class CreateTippingReports < ActiveRecord::Migration
  def change
    create_table :tipping_reports do |t|
      t.integer :competition_id
      t.integer :stage_id
      t.string :title
      t.text :report
      t.integer :status, {:default=>1}

      t.timestamps
    end
  end
end
