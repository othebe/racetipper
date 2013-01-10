class AddInvitationCodeToCompetitions < ActiveRecord::Migration
  def change
    add_column :competitions, :invitation_code, :string
  end
end
