class AddStatusToCompetitionInvitations < ActiveRecord::Migration
  def change
    add_column :competition_invitations, :status, :integer, :default=>1
  end
end
