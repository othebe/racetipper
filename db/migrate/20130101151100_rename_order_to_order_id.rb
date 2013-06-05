class RenameOrderToOrderId < ActiveRecord::Migration
  def up
	rename_column :race_stages, :order, :order_id
  end

  def down
	rename_column :race_stages, :order_id, :order
  end
end
