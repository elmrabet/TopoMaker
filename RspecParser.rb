#! /usr/bin/ruby

require 'nokogiri'

class RspecParser

  attr_reader :xml
  
  def initialize(file_name)
    file = file_name
    @xml = Nokogiri::XML(File.read(file)).remove_namespaces!
  end

  #Return all nodes
  def getAllNodes
    @xml.xpath("//node")
  end

  #Return all links        
  def getAllLinks
    @xml.xpath("//link")
  end

  def getLinkName(link)
    link.attr("client_id")
  end

  def getLinkInterfaces(link)
    tmp = link.xpath("//interface_ref")
    ret=Array.new
    tmp.each do |t|
      ret.push(t.attr("client_id"))
    end
    return ret
  end
  
  def getNodeName(node)
    node.attr("client_id")
  end

  def getInterfaces(node)
    Nokogiri::XML("#{node}").xpath("//interface")
  end

  #interface is a xml node like getInterfaces returns
  def getInterfaceName(interface)
    interface.attr("client_id")
  end

  def getOS(node)
    disk =  Nokogiri::XML("#{node}").xpath("//sliver_type/disk_image")
    if !disk.empty?
      Nokogiri::XML("#{node}").xpath("//sliver_type/disk_image").attr('name')
    else
      return nil
    end
  end
  
  #Return ip, netmask if exists, else nil
  def getNetwork(interface)
    net = Nokogiri::XML("#{interface}").xpath("//ip")
    if !net.empty?
      ip = net.attr('address')
      netmask = net.attr('netmask')
    end
    return ip, netmask
  end
  
end
