require_relative 'flavor'

module Overcloud
  module Node
    
    def list_nodes
      service('Baremetal').nodes.details
    end
    
    def create_node(node_parameters, create_flavor = False)
      node = service('Baremetal').nodes.create(node_parameters)
      create_flavor_from_node(node) if create_flavor
      node
    end

  end
end
