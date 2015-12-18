class Vlan

  attr_reader :confname, :number, :interfaces
  
  def initialize(name)
    @confname=name
    @interfaces = Array.new
  end

  def addInterface(interface)
    interfaces.push(interface)
    setKavlan(interface)
  end

  def delInterface(interface)
    interfaces.delete(interface)
    resetKavlan(interface)
  end

  def setKavlan(interface)
    if !number.nil? && !interface.realname.nil?
      %x(kavlan -j #$job_id -m #{interface.realname} -i #{@number} -s)
      puts "Kavlan #{@number} set for #{interface.realname}" if $verbose
      interface.kavlan=@number
    end
  end
  
  def resetKavlan(interface)
    puts %x(kavlan -j #$job_id -m @nodename -i DEFAULT -s)
    puts "Kavlan DEFAULT set for #{interface.realname}" if $verbose
    interface.kavlan = nil
  end

  def setNumber(nb)
    @number = nb.to_i
    interfaces.each do |i|
      setKavlan(i)
    end
  end

end
