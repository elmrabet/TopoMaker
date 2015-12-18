require 'Node'
require 'Interface'
require 'Vlan'
require 'Searcher'
require 'RspecParser'

class Initializer

  attr_reader :parser
  
  
  def initialize(file)
    @parser = RspecParser.new(file)
  end

  #Create nodes object from the rspec file
  def nodesCreate
    nodes=Array.new
    @parser.getAllNodes.each do |node|
      nodes.push(Node.new(@parser.getNodeName(node), @parser.getOS(node)))
      nodes.last.interfaces=interfacesCreate(node)
    end
    return nodes
  end

  #Create interfaces for each node from the rspec file
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

  #Create Vlan from the rspec file and add interfaces in the object
  def vlanCreate(nodeList)
    vlans = Array.new
    @parser.getAllLinks.each do |link|
      vlan = Vlan.new(@parser.getLinkName(link))
      @parser.getLinkInterfaces(link).each do |nameInt|
        interface = Searcher.searchInterface(nameInt, nodeList)
        vlan.addInterface(interface)
      end
      vlans.push(vlan)
    end
    return vlans
  end

  #Define kavlan number from the reservation and return of kavlan command
  def defVlanNumber(jobid, vlanList)
    vlanNb = %x(kavlan -V -j #{jobid} && echo $?)
    vlans = vlanNb.split("\n")
    if(vlans.delete_at(vlans.size-1).to_i != 0)
      STDERR.puts vlanNb
      exit 1
    end
    if vlans.size < vlanList.size
      STDERR.puts "Not enough VLAN in the reservation"
      STDERR.puts "You must have #{vlanList.size} vlans"
      exit 1
    end
    i=0
    vlanList.each do |v|
      v.setNumber(vlans[i])
      i+=1 
    end
  end

  #Define hostname for each node from the /var/lib/oar/$OAR_NODEFILE 
  def defNodeHostname(jobid, nodeList)
    hosts = %x(uniq /var/lib/oar/#{jobid} && echo $?)
    hostList = hosts.split("\n")
    if(hostList.delete_at(hostList.size-1).to_i != 0)
      STDERR.puts hosts
      exit 1
    end
    if hostList.size < nodeList.size
      STDERR.puts "Not enough nodes in the reservation"
      STDERR.puts "You must have #{nodeList.size} nodes"
      exit 1
    end
    i=0
    nodeList.each do |v|
      v.setNodeRealName(hostList[i])
      i+=1 
    end
  end

  #Run a kadeploy command by OS
  def deploy(nodeList)
    group = Searcher.groupOS(nodeList)
    threads = []
    group.keys.each do |k|
      threads << Thread.new {
        out = %x(kadeploy3 -e #{k} -k -m #{group[k].join(" -m ")})
        puts out if $verbose
      }
      threads.each { |t| t.join}
    end
  end

  #Write /etc/network/interfaces on each node and restart service
  def setIp(nodeList)
    threads = []
    nodeList.each do |node|
      threads << Thread.new {
        node.installAt
        node.writeConf(node.genConfInterfaces)
        node.restartIpService
      }
    end
    threads.each { |thr| thr.join }
      sleepingThread = Thread.new {
        sleep 70
        puts "Networking service restarted on each node" if $verbose
      }
      return sleepingThread
  end
  
end

