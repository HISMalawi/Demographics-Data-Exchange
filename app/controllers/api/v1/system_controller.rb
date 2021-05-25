class Api::V1::SystemController < ApplicationController

	def info
	  system("df -lh > #{Rails.root}/log/system_info.log")
	  file = []

	  File.open("#{Rails.root}/log/system_info.log").each_with_index do |f, i|
	    line = f.squish.split(" ")
	    next unless line[5] == "/" 
	    file << {size: line[1], used: line[2], avail: line[3], use: line[4]}
	  end

	  render json: file 
	end
end
