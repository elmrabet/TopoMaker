require 'Node'
require 'Interface'
require 'Vlan'
require 'Searcher'

class Initializer

  attr_reader :parser
  
  
  def initialize(file)
    @parser = RspecParser.new(file)
  end

  def nodesCreate
    nodes=Array.new
    @parser.getAllNodes.each do |node|
      nodes.push(Node.new(@parser.getNodeName(node), @parser.getOS(node)))
      nodes.last.interfaces=interfacesCreate(node)
    end
    return nodes
  end

  def interfacesCreate(node)
    interfaces=Array.new
    @parser.getInterfaces(node).each do |int|
      interfaces.push Interface.new(@parser.getInterfaceName(int))
      ip, net = @parser.getNetwork(int)
      interfaces.last.ip = ip
      interfaces.last.netmask = net
    end
    return interfaces
  end

  def vlanCreate(nodeList)
    vlans = Array.new
    @parser.getAllLinks.each do |link|
      vlan = Vlan.new(@parser.getLinkName(link))
      @parser.getLinkInterfaces do |nameInt|
        interface = Searcher.searchInterface(nameInt, nodeList)
        vlan.addInterface(interface)
      end
      vlans.push(vlan)
    end
    return vlans
  end
  
end

