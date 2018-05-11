def random_npid(len=6)
  characters = ("A".."Z").to_a.delete_if{|i|i.match(/B|I|O|Q|S|Z/)}
  digits = ("0".."9").to_a
  chars = characters + digits.to_a
  npid = ""
  1.upto(len) { |i| npid << chars[rand(chars.size-1)] }
  return npid
end

1.upto(100) do
  npid = random_npid
  Npid.create(npid: npid, version_number: 4)
end