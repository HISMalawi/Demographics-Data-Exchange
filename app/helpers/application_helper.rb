module ApplicationHelper 
  def git_version
    @git_version ||= begin
      version = `git describe --tags`.chomp
      version.present? ? version : "N/A"
    rescue
      "N/A"
    end
  end
end