class SyncJob
  include SuckerPunch::Job
  workers 1
  def perform()
   SuckerPunch.logger.info "Sucker punch at work..."
   CouchChanges.changes
   SyncJob.perform_in(1)
  end rescue SyncJob.perform_in(1)
end
