class AddInviterIdToCompetitionInvitations < ActiveRecord::Migration
  def change
    add_column :competition_invitations, :inviter_id, :integer
  end
end
