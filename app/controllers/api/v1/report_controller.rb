class Api::V1::ReportController < ApplicationController
  def show
    filename = params[:filename]
    path = Rails.root.join('public', 'reports', filename)

    if File.exist?(path)
      send_file_path, type: 'text/html', disposition: 'inline'
    else
      render 'expired', status: :gone 
    end
  end
end
