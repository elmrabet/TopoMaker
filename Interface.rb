class Interface

  #confname is the name of the interface in the input file
  #nodename is the hostname of the node associated to this interface
  #realname is the name like eth0
  #kavlan is an Object Vlan
  attr_accessor :nodename, :ip, :netmask, :kavlan, :realname
  attr_reader :confname
  
  def initialize(name)
    @confname = name
  end

  #Generate conf for /etc/network/interface
  #if not enough information : auto
  def genConf
    conf="auto #{@realname}\n"
    if (ip != nil && netmask != nil)
      conf+=%(
    iface #{realname} inet static
        address #{@ip}
        netmask #{@netmask}
)
    else
      conf+="iface #{@realname} inet dhcp\n"
    end
  end

  def toString
    ret=""
    ret+= %(- #{confname}
    realname: #{realname}
    ip: #{ip}
    netmask: #{netmask})
    return ret
  end

end
