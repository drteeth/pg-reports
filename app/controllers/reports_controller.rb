class ReportsController < ApplicationController

  def rejection_reasons
    @report = RejectionReasonReport.all
  end

end
