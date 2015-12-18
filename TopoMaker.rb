# coding: utf-8
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'optparse'
require 'Initializer'
require 'yaml'

$verbose=false

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: topomaker [options]"

  opts.on("-j JOB_ID", Integer, "Job number") do |v|
    options[:jobId] = v
    $job_id = v
  end

  opts.on("-f", "--file FILE", "Rspec configuration file") do |v|
    options[:filename] = v
  end

  opts.on("-i", "Init from file (-f and -j required)") do |v|
    options[:init] = v
  end
  
  opts.on("-v", "Run verbosely") do |v|
    $verbose = true
  end

  opts.on("-d", "--deploy", "Deploy nodes with infos in rspec file, default is jessie-x64-prod") do |v|
    options[:deploy] = v
  end
  
end.parse!

if options[:init]
  STDERR.puts "You must use -j with -i" if options[:jobId].nil?
  STDERR.puts "You must use -f with -i" if options[:filename].nil?
  exit 1 if options[:jobId].nil? || options[:filename].nil?
  
  jobid = options[:jobId]
  file = options[:filename]
  
  init = Initializer.new(file)
  nodes = init.nodesCreate()
  vlans = init.vlanCreate(nodes)

  #Attribution des hostname aux Nodes
  init.defNodeHostname(jobid, nodes)

  #Attribution des hostnames aux Interfaces
  nodes.each do |n|
    n.setInterfacesHostname
  end

  if options[:deploy]
    #Deploiement des noeuds
    puts "Deployment..." if $verbose
    init.deploy(nodes)
  end

  rsNetServThread = init.setIp(nodes)

  #Attribution du numéro des Vlans
  init.defVlanNumber(jobid, vlans)

  #Affichages
  # nodes.each do |n|
  #   puts n.toString
  # end

  puts nodes.to_yaml

  #Attente du redémarrage du service networking
  rsNetServThread.join
  
end
