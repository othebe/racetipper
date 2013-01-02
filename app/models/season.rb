class Season < ActiveRecord::Base
  attr_accessible :year
  belongs_to :race
end
