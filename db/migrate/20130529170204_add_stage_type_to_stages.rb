class AddStageTypeToStages < ActiveRecord::Migration
  def change
    add_column :stages, :stage_type, :string, {:default=>'F'}
  end
end
