module FootPrintService
  def self.create(params)
    npid = params[:npid]
    user_id = params[:user_id]
    location_id = params[:location_id]
    
    footprint = CouchdbFootPrint.create(npid: npid, user_id: user_id, location_id: location_id)
    return footprint
  end
end