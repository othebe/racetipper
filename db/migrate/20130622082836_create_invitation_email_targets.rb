class CreateInvitationEmailTargets < ActiveRecord::Migration
  def change
    create_table :invitation_email_targets do |t|
      t.integer :race_id
      t.integer :scope
      t.string :target

      t.timestamps
    end
  end
end
