require 'json'
require 'rest-client'

class Node

  attr_reader :nodeConfName  #The name of the node in conf file
  attr_accessor :interfaces, :os, :nodeRealName, :toInstall
  
  def initialize(confname, op_sys=nil)
    @nodeConfName = confname
    @os = op_sys.nil? ? 'jessie-x64-min' : op_sys
    @interfaces = Array.new
    @toInstall = Array.new
  end

  def addInterface(interface)
    @interfaces.push(interface)
  end

  def genConfInterfaces
    conf = %(auto lo
iface lo inet loopback
)
    interfaces.each do |i|
      conf += i.genConf
    end
    return conf
  end

  def writeConf(conf)
    %x(ssh root@#{nodeRealName} "cat > /etc/network/interfaces << EOF 
#{conf} 
EOF")
  end

  #Install at command on the node
  def installAt
    %x(ssh root@#{nodeRealName} "apt-get update &> /dev/null ; apt-get --yes install at &> /dev/null")
  end

  #Restart ip service after 1 min => require At
  def restartIpService
    %x(ssh root@#{nodeRealName} "echo \'service networking restart\' | at now + 1 minute")
  end

  def setNodeRealName(host)
    @nodeRealName = host
  end

  #Set the hostname and device name of the interface from the API
  def setInterfacesHostname
    #API
    api_url = "https://api.grid5000.fr/sid/"
    api = RestClient::Resource.new(api_url, :verify_ssl => false)
    tab = @nodeRealName.split("\.")
    nodeName = tab[0]
    # nodeName = @nodeRealName.scan(/\w+-[0-9]+/)[0]
    cluster = nodeName.scan(/\w+/)[0]
    site = tab[1]
    apinode =  JSON.parse api["sites/#{site}/clusters/#{cluster}/nodes/#{nodeName}.json"].get(:accept => 'application/json')
    devices = Array.new
    addresses = Array.new
    apinode['network_adapters'].each do |na|
      if na['enabled'] == true && na['device'].include?("eth") #Only eth device will be used
        devices.push na['device']
        if !na['network_address'].nil?
          addresses.push na['network_address']
        else
          addresses.push "#{nodeName}-#{na['device']}.#{site}.grid5000.fr"
        end
      end
    end
    if addresses.size < @interfaces.size
      STDERR.puts "Not enough network adapters on #{@nodeRealName}"
      STDERR.puts "This node must have #{@interfaces.size} interfaces"
      exit 1
    end
    i=0
    @interfaces.each do |v|
      v.setRealName(addresses[i])
      v.setDevice(devices[i])
      i+=1
    end
  end

  def installToInstall
    if !toInstall.empty?
      %x(ssh root@#{nodeRealName} "apt-get update &> /dev/null ; apt-get --yes install #{@toInstall.join(" ")} &> /dev/null")
    end
  end

end
