require 'benchmark'

Benchmark.bm do |x|
  x.report {system "rake -f Rakefile1 -q"}
  x.report {system "rake -f Rakefile2 -q"}
end