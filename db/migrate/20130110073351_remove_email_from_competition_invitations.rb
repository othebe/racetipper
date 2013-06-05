class RemoveEmailFromCompetitionInvitations < ActiveRecord::Migration
  def up
	remove_column :competition_invitations, :email
  end

  def down
	add_column :competition_invitations, :email, :string
  end
end
