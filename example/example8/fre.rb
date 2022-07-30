exit unless ARGV.size >= 1

class CNode
  attr_reader :char, :count
  attr_accessor :nxt

  def initialize char, nxt=nil, count=1
    @char = char
    @nxt = nxt
    @count = count
  end

  def inc
    @count += 1
  end
end

class String
  def c_hash
    self.hash % HSIZE
  end
end

HSIZE = 1001
@t = Array.new HSIZE
@t = @t.map {CNode.new(nil, nil, 0)}
@n = 0

ARGV.each do |file|
  s = File.read file
  s.each_char do |c|
    @n += 1
    n = c.c_hash
    cn = @t[n]
    while cn.nxt
      if cn.nxt.char == c
        cn.nxt.inc
        break
      end
      cn = cn.nxt
    end
    unless cn.nxt
      cn.nxt = CNode.new(c, nil, 1)
    end
  end
end

@a = []
@t.each do |cn|
  while cn.nxt
    @a << [cn.nxt.char, cn.nxt.count]
    cn = cn.nxt
  end
end

@a.sort!{|a,b| -(a[1] <=> b[1])} 

print "総文字数： #{@n}\n"
print "頻度の上位10文字\n"
0.upto(9) do |i|
  printf "%-6s => % 3d\n", @a[i][0].inspect, @a[i][1]
end
