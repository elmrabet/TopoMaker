class Searcher

  def self.searchInterface(name, nodeList)
    nodeList.each do |node|
      node.interfaces.each do |int|
        return int if int.confname == name
    end
  end
    return nil
end
