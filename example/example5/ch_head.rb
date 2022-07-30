files = (1..4).map {|n| "sec#{n}.md"}
files.each do |file|
  s = File.read(file)
  s.gsub!(/^###/,"#")
  s.gsub!(/^####/,"##")
  s.gsub!(/^#####/,"###")
  File.write(file,s)
end
