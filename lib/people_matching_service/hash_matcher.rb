# HashMatcher - Computes the degree of similarity between two hash-like
# objects.
#
# @example Basic match
#   >> hash = {foo: 'bar', bar: 'foo'}
#   >> hash_matcher = HashMatcher.new(hash)
#   >> hash_matcher.match(hash)
#   => 1.0
#   >> hash_matcher.match({foo: 'bar', bar: 'bar'})
#   => 0.5
#
# @example Custom match
#   >> hash = {foo: 'bar', bar: 'foo'}
#   >> hash_matcher = HashMatcher.new(hash, {
#   >>  foo: {
#   >>    scorer: lambda {|a, b| a == b ? 1.0 : 0.0},   # This is the default scoring function
#   >>    weight: 2
#   >>  }
#   >> })
#   >> hash_matcher.match(hash)
#   => 1.0
#   >> (hash_matcher.match({foo: 'bar'}) * 100).round    # Expect 2 / 3 == 0.67 where 2 is foo score and 3 is total score
#   => 67
#   >> (hash_matcher.match({bar: 'foo'}) * 100).round    # Expect 1 / 3 == 0.33 where 1 is bar score and 3 is total score
#   => 33
#
# NOTE: The match method returns a score in range [0, 1]
class HashMatcher

  # Bind hash to be matched to other hashes using match method.
  #
  # Parameters:
  # hash        - The hash to be bound to this matcher
  # field_specs - An optional map of fields in bound hash to their
  #               weights and scoring (matching) functions.
  #
  #               NOTE: A weight can be any value, it defaults to 1 and
  #               the scoring function must return value in [0, 1] only.
  def initialize(hash, field_specs: {}, include: nil, exclude: nil)
    # Check if field should be matched
    should_include_field = lambda do |field|
      !(include.respond_to? :include? and !include.include? field) \
        and !(exclude.respond_to? :include? and exclude.include? field)
    end

    # Retrieve field spec - return default spec if not found
    get_field_spec = lambda do |field|
      spec = field_specs[field]

      if spec.nil? or spec.empty?
        [DEFAULT_SCORER, DEFAULT_WEIGHT]
      else
        [(spec[:scorer] or DEFAULT_SCORER), (spec[:weight] or DEFAULT_WEIGHT)]
      end
    end

    # Create the archetype everything else is matched to (using the match method)
    @archetype = hash.inject({}) do |archetype, fv_pair|
      field, value = fv_pair

      next archetype unless should_include_field.(field)

      scorer, weight = get_field_spec.(field)

      archetype[field] = {value: value, scorer: scorer, weight: weight}
      archetype
    end
  end

  # match - Returns score in [0, 1] with 1 => full match and 0 => no match.
  def match(hash)
    score, total_score = @archetype.inject([0, 0]) do |accum, fdef_pair|
      current_score, total_score = accum
      field, field_spec = fdef_pair

      scorer = field_spec[:scorer]
      weight = field_spec[:weight]

      # We love symbols for field names but string are welcome too:
      rvalue = hash[field] or hash[field.to_s]
      score = rvalue ? scorer.(field_spec[:value], rvalue) * weight : 0

      [current_score + score, total_score + weight]
    end

    score.to_f / total_score
  end

  private

  DEFAULT_SCORER = lambda { |lvalue, rvalue| lvalue == rvalue ? 1.0 : 0.0 }
  DEFAULT_WEIGHT = 1.0
end
