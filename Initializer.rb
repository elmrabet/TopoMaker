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
      nodes.last.toInstall=listToInstall(node)
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
        if interface.nil?
          STDERR.puts "The interface #{nameInt} set in link #{vlan.confname} does not exists"
          exit 1
        end
        vlan.addInterface(interface)
      end
      vlans.push(vlan)
    end
    return vlans
  end

  def listToInstall(node)
    ret = Array.new
    @parser.getAptNode(node).each do |apt|
      ret.push(apt.attr('name'))
    end
    return ret
  end

  #Define kavlan number from the reservation and return of kavlan command
  def defVlanNumber(jobid, vlanList)
    vlanNb = %x(kavlan -V -j #{jobid} | uniq && echo $?)
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
      puts "Deploying #{k}" if $verbose
      threads << Thread.new {
        out = %x(kadeploy3 -e #{k} -k -m #{group[k].join(" -m ")})
        puts out if $verbose
      }
    end
    threads.each { |t| t.join}
  end

  #Write /etc/network/interfaces on each node and restart service
  def setIp(nodeList)
    puts "Defining ip..."
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

  def resetAlltoDefaultVlan(nodeList)
    puts "Reset all nodes to default Vlan..." if $verbose
    command=""
    nodeList.each do |node|
      command+="-m #{node.nodeRealName} "
    end
    %x(kavlan -i DEFAULT -s #{command})
  end

  def putSSHkey(nodeList)
    dir=%x(mktemp -d XXXXX).strip
    %x(ssh-keygen -t rsa -f #{dir}/id_rsa -P "" -q)
    nodeList.each do |node|
      %x(scp #{dir}/id_rsa root@#{node.nodeRealName}:.ssh/id_rsa && ssh-copy-id -i #{dir}/id_rsa.pub root@#{node.nodeRealName})
    end
    %x(rm -rf #{dir})
  end

  def installAll(nodes)
    puts "Installing package..."
    threads = []
    nodes.each do |node|
      threads << Thread.new {node.installToInstall}
    end
    threads.each do |t|
      t.join
    end
  end

#ajouter par yassine
def lastnode(jobid)
    hosts = %x(uniq /var/lib/oar/#{jobid})
    hostList = hosts.split("\n")
    hostlast=hostList[$nbr]
    puts"le dernier noeud est #{hostlast}"
    hostlastadresse=%x(host #{hostlast} )
    puts hostlastadresse
    adressetab=hostlastadresse.split( )
    adresse=adressetab.last
    return adresse
end


#ajouter par yassine
  def confovs(nodes)
     nodes.each do |node|
     puts "#{node.nodeRealName}"
     node.ovs
     end
  end   

#ajouter par yassine
  def confcontroleur(nodes,adresse)
     nodes.each do |node|
     puts "#{node.nodeRealName}"
     node.controleur(adresse)
     end
  end   

#ajouter par yassine 

   def lancementcontroleur(adresse)
     %x(ssh root@#{adresse} "git clone http://github.com/noxrepo/pox")
     %x(ssh root@#{adresse} "cd pox ; ./pox.py samples.pretty_log forwarding.l2_learning")

   end




end
