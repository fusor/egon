require_relative 'image'

module Overcloud
  module Flavor

    def list_flavors
      service('Compute').flavors.all
    end
    
    def get_flavor(flavor_id)
      service('Compute').flavors.get(flavor_id)
    end

    def create_flavor(flavor_parameters)
      flavor = service('Compute').flavors.create(flavor_parameters)
      if flavor_parameters.key?(:extra_specs)
        create_flavor_extra_specs(flavor.id, flavor_parameters[:extra_specs])
      end
    end

    def get_flavor_extra_specs(flavor_id)
      get_flavor(flavor_id).metadata
    end

    def create_flavor_extra_specs(flavor_id, extra_specs)
      get_flavor(flavor_id).create_metadata(extra_specs)
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
        :extra_specs => {
          :cpu_arch => cpu_arch,
          :'baremetal:deploy_kernel_id' => get_baremetal_deploy_kernel_image.id,
          :'baremetal:deploy_ramdisk_id' => get_baremetal_deploy_ramdisk_image.id
        }
      }
      
      if !flavor_exists?(flavor_parameters)
        create_flavor(flavor_parameters)
      end
    end
    
    def flavor_exists?(flavor_parameters)
      for flavor in list_flavors
        if flavor.ram == flavor_parameters[:ram].to_i &&
            flavor.vcpus == flavor_parameters[:vcpus].to_i &&
            flavor.disk == flavor_parameters[:disk].to_i &&
            flavor.metadata['cpu_arch'] == flavor_parameters[:extra_specs][:cpu_arch]
          return true
        end
      end
      false
    end

  end
end
