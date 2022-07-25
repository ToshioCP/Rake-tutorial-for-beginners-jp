require 'rake/clean'

sources = FileList["sec*.md"]

task default: %w[docs/はじめてのRake.html docs/style.css docs/word.png docs/html.png]

file "docs/はじめてのRake.html" => %w[はじめてのRake.md docs] do |t|
  sh "pandoc -s --toc -c style.css -o #{t.name} #{t.source}"
end
CLEAN << "はじめてのRake.md"

file "はじめてのRake.md" => sources do |t|
  firstrake = t.sources.inject("") {|s1, s2| s1 << File.read(s2) + "\n"}
  File.write("はじめてのRake.md", firstrake)
end

file "docs/style.css" => %w[style.css docs] do |t|
  cp t.source, t.name
end

%w[docs/word.png docs/html.png].each do |image|
  source = image.sub(/docs/,"image")
  file image => [source, "docs"] do |t|
    cp t.source, t.name
  end
end

directory "docs"
CLOBBER << "docs"
