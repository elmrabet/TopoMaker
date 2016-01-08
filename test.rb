$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'RspecParser'
require 'Initializer'

init = Initializer.new('samples_in/rspec_sample.xml')
rs = RspecParser.new('samples_in/rspec_sample.xml')
puts "--------------"
init.nodesCreate.each do |n|
  puts rs.getAptNode(n)
end

