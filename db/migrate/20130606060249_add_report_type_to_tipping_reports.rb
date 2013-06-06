class AddReportTypeToTippingReports < ActiveRecord::Migration
  def change
    add_column :tipping_reports, :report_type, :integer, {:default=>1}
  end
end
