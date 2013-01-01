class Metadata < ActiveRecord::Base
  attr_accessible :data, :data_type, :object_id, :object_type, :title
end
