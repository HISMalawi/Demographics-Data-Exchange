require_relative "../hash_matcher"

RSpec.describe "HashMatcher" do
  describe "match" do
    it "perfectly matches same object" do
      archetype = {foo: :foo, bar: :bar}
      matcher = HashMatcher.new archetype

      # NOTE: scores are floating point values hence rounding them to allow
      # for precise equality tests and to rid ourselves of precision errors
      score = matcher.match archetype
      expect((score * 100).round).to eq(100)
    end

    it "partially matches partially similar objects" do
      archetype = {foo: :foo, bar: :bar}
      matcher = HashMatcher.new archetype
      score = matcher.match({foo: :foo, bar: :foo})
      expect((score * 100).round).to eq(50)
    end

    it "partially matches partial objects" do
      archetype = {foo: :foo, bar: :bar}
      matcher = HashMatcher.new archetype

      score = matcher.match({foo: :foo})
      expect((score * 100).round).to eq(50)

      score = matcher.match({bar: :bar})
      expect((score * 100).round).to eq(50)
    end

    it "uses bound scoring function and weight for matching" do
      archetype = {foo: 1.00001, bar: :bar}
      field_specs = {
        foo: {
          scorer: lambda { |a, b| a.floor == b.floor ? 1.0 : 0.0 },
          # Trim mantissa for precise equality testing
          weight: 2.0,
        },
      }
      matcher = HashMatcher.new archetype, field_specs: field_specs

      score = matcher.match archetype
      expect((score * 100).round).to eq(100)

      score = matcher.match({foo: 1.0, bar: :unbar})
      expect((score * 100).round).to eq(67)  # 2 / 3 where 2 is :foo weight and 3 is total score

      score = matcher.match({foo: 2.0, bar: :bar})
      expect((score * 100).round).to eq(33)  # 1 / 3 where is :bar weight and 3 is total score
    end
  end
end
