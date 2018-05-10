class SyncJob
  include SuckerPunch::Job
  workers 1
  def perform()
   SuckerPunch.logger.info "Sucker punch at work..."
   SyncJob.perform_in(5)
  end #rescue SyncJob.perform_in(5)
end
