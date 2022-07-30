task :goodby, [:person1, :person2] do |t, args|
  print "Good by, #{args.person1}.\n"
  print "Good by, #{args.person2}.\n"
end
  