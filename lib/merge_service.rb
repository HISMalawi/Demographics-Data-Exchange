
module MergeService

  def self.merge(primary_doc_id, secondary_doc_id,current_user)
    primary_person    = PersonDetail.find_by_person_uuid(primary_doc_id)
    return [] if primary_person.blank?
    secondary_person  = PersonDetail.find_by_person_uuid(secondary_doc_id)
    return [] if secondary_person.blank?
=begin
    we look for any attributes that primary_person does not have 
    but secondary_person has and we give those
    attributes to the primary_person
=end
    audit_record = secondary_person.dup

    ActiveRecord::Base.transaction do
      person = JSON.parse(audit_record.to_json)
      secondary_person.voided = 1
      secondary_person.voided_by = current_user.id
      secondary_person.date_voided = Time.now
      secondary_person.location_updated_at = current_user.location_id
      secondary_person.last_edited = Time.now
      secondary_person.void_reason = "dde merged with: #{primary_person.person_uuid}"
      PersonDetailsAudit.create!(person)
      secondary_person.update(JSON.parse(secondary_person.to_json))
    end
    return PersonService.get_person_obj(primary_person)
  end

  def self.rollback_merge(primary_doc_id, secondary_doc_id,current_user)
    [primary_doc_id, secondary_doc_id].each do |doc_id|
      ActiveRecord::Base.transaction do
        person = PersonDetail.find_by_person_uuid(doc_id)
        return [] if person.blank? || !voided?(person)
        #audit routine
        audit_person = person.dup
        audit_person = JSON.parse(audit_person.to_json)
        audit_person.delete('id')
        audit_person.delete('updated_at')
        PersonDetailsAudit.create!(audit_person)
        #audit end
        person.voided = 0
        person.voided_by = nil
        person.date_voided = nil
        person.location_updated_at = current_user.location_id
        person.last_edited = Time.now
        person.void_reason = nil
        person.update(JSON.parse(person.to_json))
      end
    end
  end
end
