class Vlan

  attr_reader :confname
  attr_accessor :number, :interfaces
  
  def initialize(name)
    @confname=name
  end

  def addInterface(interface)
    interfaces.push(interface)
    setKavlan(interface)
  end

  def delInterface(interface)
    interfaces.delete(interface)
  end

  def setKavlan(interface)
    #TODO kavlan -m @nodename -i @number -s
    interface.kavlan=self
  end
  
  
  def resetKavlan(interface)
    #TODO kavlan -m @nodename -i DEFAULT -s
    interface.kavlan = nil
  end

end
