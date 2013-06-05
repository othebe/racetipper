class CreateCompetitionInvitations < ActiveRecord::Migration
  def change
    create_table :competition_invitations do |t|
      t.integer :competition_id
      t.integer :user_id
      t.string :email

      t.timestamps
    end
  end
end
