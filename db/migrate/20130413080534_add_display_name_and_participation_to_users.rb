class AddDisplayNameAndParticipationToUsers < ActiveRecord::Migration
  def change
	add_column :users, :display_name, :string
	add_column :users, :in_grand_competition, :boolean, :default=>true
  end
end
