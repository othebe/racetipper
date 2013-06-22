class InvitationEmailTarget < ActiveRecord::Base
  attr_accessible :race_id, :scope, :target
end
