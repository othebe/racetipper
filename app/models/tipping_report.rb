class TippingReport < ActiveRecord::Base
  attr_accessible :competition_id, :report, :stage_id, :status, :title
end