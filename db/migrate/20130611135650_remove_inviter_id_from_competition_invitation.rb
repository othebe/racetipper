class RemoveInviterIdFromCompetitionInvitation < ActiveRecord::Migration
  def up
    remove_column :competition_invitations, :inviter_id
  end

  def down
    add_column :competition_invitations, :inviter_id, :integer
  end
end
