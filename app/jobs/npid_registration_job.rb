# class NpidRegistrationJob
#   include SuckerPunch::Job
#   workers 1
#   def perform()
#    SuckerPunch.logger.info "NPID registration at work ..."
#    NpidRegistrationService.assign_ids
#    #NpidRegistrationJob.perform_in(1)
#   end #rescue NpidRegistrationJob.perform_in(1)
# end
