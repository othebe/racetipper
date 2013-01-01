class CompetitionInvitation < ActiveRecord::Base
  attr_accessible :competition_id, :email, :user_id
end
