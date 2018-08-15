class Api::V1::PeopleController < ApplicationController
  def create
    errors = ValidateParams.add_person(params)
    if errors.blank?
      person = PersonService.create(params, current_user)
      render json: person
    else
      render json: errors
    end
  end

  def assign_npid
    person = PersonService.assign_npid(params)
    render json: person
  end

  def search_by_name_and_gender
    errors = ValidateParams.search_by_name_and_gender(params)
    if errors.blank?
      search_results = PersonService.search_by_name_and_gender(params)
      render json: search_results
    else
      render json: errors
    end
  end

  def search_by_npid
    errors = ValidateParams.search_by_npid(params)
    if errors.blank?
      search_results = PersonService.search_by_npid(params)
      render json: search_results
    else
      render json: errors
    end
  end

  def search_by_doc_id
    errors = ValidateParams.search_by_doc_id(params)
    if errors.blank?
      search_results = PersonService.search_by_doc_id(params)
      render json: search_results
    else
      render json: errors
    end
  end

  def search_by_attributes
    errors = ValidateParams.search_by_attributes(params)
    if errors.blank?
      search_results = PersonService.search_by_attributes(params)
      render json: search_results
    else
      render json: errors
    end
  end

  def update_person
    errors = ValidateParams.update_person(params)
    if errors.blank?
      person = PersonService.update_person(params)
      render json: person
    else
      render json: errors
    end
  end

  def potential_duplicates
    errors = ValidateParams.potential_duplicates(params)
    if errors.blank?
      potential_duplicates = PersonService.potential_duplicates(params)
      render json: potential_duplicates
    else
      render json: errors
    end
  end

  def merge_people
    errors = ValidateParams.merge_people(params)
    if errors.blank?
      merge_results = MergeService.merge(params[:primary_person_doc_id], params[:secondary_person_doc_id])
      render json: merge_results
    else
      render json: errors
    end
  end

  def reassign_npid
    person = PersonService.assign_npid(params)
    render json: person
  end
end
