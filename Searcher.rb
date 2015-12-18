class Searcher
  
  def self.searchInterface(name, nodeList)
    nodeList.each do |node|
      node.interfaces.each do |int|
        return int if int.confname == name
      end
    end
    return nil
  end

  #Group node in Hash by OS
  def self.groupOS(nodeList)
    group = {}
    nodeList.each do |node|
      if group.key?(node.os)
        group[node.os].push(node.nodeRealName)
      else
        group[node.os] = [node.nodeRealName]
      end
    end
    return group
  end
  
end
