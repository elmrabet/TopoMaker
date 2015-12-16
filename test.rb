$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'RspecParser'
require 'Initializer'

rs = Initializer.new('samples_in/rspec_sample.xml')
puts "--------------"
rs.nodesCreate.each do |n|
  puts n.toString
end

