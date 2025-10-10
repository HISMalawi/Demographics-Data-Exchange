class UpdateMovementJob < ApplicationJob
  queue_as :default

  def perform(person_uuid)
    # Do something later
    sites_visited = FootPrint.where(person_uuid:).select(:location_id).distinct.count
    record = MovementCache.find_by(person_uuid:)
    if record
      record.update(sites_visited:)
    else
      MovementCache.create!(person_uuid:, sites_visited:)
    end
  end
end
