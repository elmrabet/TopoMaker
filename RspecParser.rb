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

  def getInterfaces(node)
    Nokogiri::XML("#{node}").xpath("//interface")
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
    puts net = Nokogiri::XML("#{interface}").xpath("//ip")
    ip = net.attr('address')
    netmask = net.attr('netmask')
    return ip, netmask
  end
  
end

rs = RspecParser.new('samples_in/rspec_sample.xml')
puts rs.getNetwork rs.getInterfaces(rs.getAllNodes[2])
