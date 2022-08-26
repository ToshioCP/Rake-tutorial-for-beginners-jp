require 'rake/clean'

sources = FileList["sec*.md"]

task default: %w[docs/はじめてのRake.html docs/style.css docs/word.png docs/html.png docs/index.html docs/.nojekyll]

file "docs/はじめてのRake.html" => %w[はじめてのRake.md docs] do |t|
  sh "pandoc -s --toc -c style.css -o #{t.name} #{t.source}"
end
CLEAN << "はじめてのRake.md"

file "はじめてのRake.md" => sources do |t|
  File.write(t.name, t.sources.inject("") {|s1, s2| s1 << File.read(s2) + "\n"})
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

file "docs/index.html" do |t|
  File.write(t.name, <<'EOS')
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="" xml:lang="">
<head>
  <meta http-equiv="refresh" content="0 %E3%81%AF%E3%81%98%E3%82%81%E3%81%A6%E3%81%AERake.html">
</head>
<body></body>
</html>
EOS
end

file "docs/.nojekyll" do |t|
  touch t.name
end

directory "docs"
CLOBBER << "docs"
