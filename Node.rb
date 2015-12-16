class Node

  attr_reader :nodeConfName  #The name of the node in conf file
  attr_accessor :interfaces, :os, :nodeRealName
  
  def initialize(confname, op_sys=nil)
    @nodeConfName = confname
    @os = op_sys.nil? ? 'jessie-x64-prod' : op_sys
    @interfaces = Array.new
  end

  def addInterface(interface)
    @interfaces.push(interface)
  end

  def genConfInterfaces
    conf = ""
    interfaces.each do |i|
      conf += i.genConf
    end
  end

  def toString
    ret=""
    ret+= %(- #{nodeConfName}
   name: #{nodeRealName}
   os: #{os}
   interfaces:   
)
    interfaces.each do |i|
      ret+=i.toString
    end
    return ret
  end
  
end
