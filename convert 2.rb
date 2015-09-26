txt = File.read("Change.txt")
loop { break unless txt.gsub!(/(['][^']*)[\n]([^']*['])/m, '\1|\2')}
txt.gsub!(/['][|][']/,"'\n'")
txt.gsub!(/[|]/," ")
f = File.open("converted.csv", "w")
f.puts txt
f.close

  
