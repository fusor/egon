module Overcloud
  module Flavor

    def list_flavors
      service('Compute').flavors.all
    end
    
    def get_flavor(flavor_id)
      service('Compute').flavors.get(flavor_id)
    end
    
    def create_flavor(flavor_parameters)
      service('Compute').flavors.create(flavor_parameters)
    end
    
    def create_flavor_from_node(node)
      cpus = node.properties['cpus']
      memory_mb = node.properties['memory_mb']
      local_gb = node.properties['local_gb']
      cpu_arch = node.properties['cpu_arch']
      
      flavor_parameters = {
        :name => 'Flavor-' + cpus + '-' + cpu_arch + '-' + memory_mb + '-' + local_gb,
        :ram => memory_mb,
        :vcpus => cpus,
        :disk => local_gb,
        :is_public => true,
      }
      
      if !flavor_exists?(flavor_parameters)
        create_flavor(flavor_parameters)
      end
    end
    
    def flavor_exists?(flavor_parameters)
      for flavor in list_flavors
        if flavor.ram == flavor_parameters[:ram].to_i &&
            flavor.vcpus == flavor_parameters[:vcpus].to_i &&
            flavor.disk == flavor_parameters[:disk].to_i
          return true
        end
      end
      false
    end

  end
end
