require_relative 'bantu_soundex'

PersonDetail.unscoped.find_in_batches do | batch |
  Parallel.each(batch) do |person|
    person.update(first_name_soundex: person.first_name.soundex,
                  last_name_soundex: person.last_name.soundex)
  end
end
