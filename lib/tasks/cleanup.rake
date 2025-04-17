namespace :reports do 
  desc "Delete report files older than 7 days"
  task cleanup_old: :environment do 
    report_path = Rails.root.join('public', 'reports', '*.html')
    Dir[report_path].each do |file|
      if File.mtime(file) < 7.days.ago
        Rails.logger.info "Deleting old report: #{file}"
        File.delete(file)
      end
    end
  end
end 