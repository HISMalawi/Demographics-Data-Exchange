module ApplicationHelper
  def git_version
    @git_version ||= begin
      # Make sure this only runs in development/production where Git exists
      version = `git describe --tags --abbrev=0`.chomp
      version.present? ? version : "N/A"
    rescue
      "N/A"
    end
  end
end