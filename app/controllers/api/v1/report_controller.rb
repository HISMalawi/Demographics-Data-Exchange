class Api::V1::ReportController < ApplicationController
  skip_before_action :authenticate_request, only: [:show]

  def show
    filename = "#{params[:filename]}.html"
    path = Rails.root.join('public', 'reports', filename)

    if File.exist?(path)
      send_file path, type: 'text/html', disposition: 'inline'
    else
      render 'expired', status: :gone
    end
  end
  
end
