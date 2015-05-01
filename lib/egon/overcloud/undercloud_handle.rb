require 'fog'

class UndercloudHandle

  def initialize(username, password, auth_url, port = 5000)
    @username = username
    @password = password
    @auth_url = auth_url
    @port = port
  end

  def get_plan(plan_name)
    service('Planning').plans.find_by_name(plan_name)
  end

  def list_deployment_roles
    service('Planning').roles
  end

  def edit_plan_parameters(plan_name, parameters)
    get_plan(plan_name).patch(:parameters => parameters)
  end

  def edit_deployment_role_count(plan_name, role_name, count)
    parameter = {"name" => role_name + "-1::count", "value" => count.to_s}
    edit_plan_parameters(plan_name, [count_parameter])
  end

  def edit_deployment_role_image(plan_name, role_name, image_uuid)
    parameter = {"name" => role_name + "-1::Image", "value" => image_uuid}
    edit_plan_parameters([parameter])
  end

  def edit_deployment_role_flavor(plan_name, role_name, flavor_name)
    parameter = {"name" => role_name + "-1::Flavor", "value" => flavor_name}
    edit_plan_parameters(plan_name, [parameter])
  end

  def get_stack(stack_name)
    service('Orchestration').stacks.get(stack_name)
  end

  def list_nodes
    service('Baremetal').nodes.details
  end

  def create_node(node_parameters, create_flavor = False)
    node = service('Baremetal').nodes.create(node_parameters)
    create_flavor_from_node(node) if create_flavor
    node
  end

  def list_flavors
    service('Compute').flavors.all
  end

  def get_flavor(flavor_id)
    service('Compute').flavors.get(flavor_id)
  end

  def create_flavor(flavor_parameters)
    service('Compute').flavors.create(flavor_parameters)
  end

  def list_images
    service('Image').images
  end

  def deploy_plan(plan)
    stack_parameters = {
      :stack_name => plan.name,
      :template => plan.master_template,
      :environment => plan.environment,
      :files => plan.provider_resource_templates,
      :password => UNDERCLOUD_PASSWORD,
      :timeout_mins => 60,
      :disable_rollback => true
    }
    service('Orchestration').stacks.new.save(stack_parameters)
  end

  private

  def service(service_name)
    fog_parameters = {
      :provider           => 'OpenStack',
      :openstack_auth_url => 'http://' + @auth_url + ':' + @port.to_s + '/v2.0/tokens',   
      :openstack_username => @username,
      :openstack_api_key  => @password,
    }

    if service_name == 'Planning'
      return Fog::Openstack.const_get(service_name).new(fog_parameters)
    end
    return Fog.const_get(service_name).new(fog_parameters)
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
