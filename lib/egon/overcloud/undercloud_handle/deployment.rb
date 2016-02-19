module Overcloud
  module Deployment

    # BASE PLAN ACTIONS

    def list_plans
      uri = "#{base_tripleo_api_url}/plans"
      response = Fog::Core::Connection.new(uri, false).request({
            :expects => 200,
            :headers => {'Content-Type' => 'application/json',
                         'Accept' => 'application/json',
                         'X-Auth-Token' => auth_token},
            :method  => 'GET'
          })
      body = Fog::JSON.decode(response.body)
      body['plans']
    end
 
    def get_plan(plan_name)
      uri = "#{base_tripleo_api_url}/plans/#{plan_name}"
      response = Fog::Core::Connection.new(uri, false).request({
            :expects => 200,
            :headers => {'Content-Type' => 'application/json',
                         'Accept' => 'application/json',
                         'X-Auth-Token' => auth_token},
            :method  => 'GET'
          })
      body = Fog::JSON.decode(response.body)
      body['plan']
    end

    def deploy_plan(plan_name)
      plan = get_plan(plan_name)

      # ensure that nodes are in correct state
      for node in list_nodes
        node.set_provision_state('provide') if node.provision_state == 'manageable'
      end

      # assign all unassigned roles; make sure their count is 0
      default_flavor = list_flavors[0]
      for role in list_deployment_roles
        flavor_parameter_name = role.name + "-1::Flavor"
        flavor_parameter_value = get_plan_parameter_value(plan_name, flavor_parameter_name)
        unless list_flavors.map { |flavor| flavor.name }.include? flavor_parameter_value.to_s
          edit_plan_deployment_role_count(plan_name, role.name, 0)
          edit_plan_deployment_role_flavor(plan_name, role.name, default_flavor.name)
        end
      end

      uri = "#{base_tripleo_api_url}/plans/#{plan_name}/deploy"
      response = Fog::Core::Connection.new(uri, false).request({
            :expects => 200,
            :headers => {'Content-Type' => 'application/json',
                         'Accept' => 'application/json',
                         'X-Auth-Token' => auth_token},
            :method  => 'PUT'
          })
    end

    ## PLAN PARAMETER METHODS

    def get_plan_parameters(plan_name)
      uri = "#{base_tripleo_api_url}/plans/#{plan_name}/parameters"
      response = Fog::Core::Connection.new(uri, false).request({
            :expects => 200,
            :headers => {'Content-Type' => 'application/json',
                         'Accept' => 'application/json',
                         'X-Auth-Token' => auth_token},
            :method  => 'GET'
          })
      body = Fog::JSON.decode(response.body)
      body['parameters']['Parameters']
    end

    def get_plan_parameter_value(plan_name, parameter_name)
      parameters = get_plan_parameters(plan_name)
      if parameters.key?(parameter_name)
        parameters[parameter_name]["Default"]
      else
        nil
      end
    end

    def edit_plan_parameters(plan_name, parameters)
      uri = "#{base_tripleo_api_url}/plans/#{plan_name}/parameters"
      response = Fog::Core::Connection.new(uri, false).request({
            :expects => 200,
            :headers => {'Content-Type' => 'application/json',
                         'Accept' => 'application/json',
                         'X-Auth-Token' => auth_token},
            :method  => 'PATCH',
            :body => Fog::JSON.encode(parameters),
          })
    end

    def edit_plan_deployment_role_count(plan_name, role_name, count)
      parameters = { role_name + "Count" => count.to_s}
      edit_plan_parameters(plan_name, parameters)
    end

    def edit_plan_deployment_role_image(plan_name, role_name, image_name)
      parameters = { role_name.downcase + "Image" => image_name}
      edit_plan_parameters(plan_name, parameters)
    end

    def edit_plan_deployment_role_flavor(plan_name, role_name, flavor_name)
      parameter = {"name" => role_name + "-1::Flavor", "value" => flavor_name}
      edit_plan_parameters(plan_name, [parameter])
    end

    ## PLAN ENVIRONMENT ACTIONS

    def get_plan_environments(plan_name)
      uri = "#{base_tripleo_api_url}/plans/#{plan_name}/environments"
      response = Fog::Core::Connection.new(uri, false).request({
            :expects => 200,
            :headers => {'Content-Type' => 'application/json',
                         'Accept' => 'application/json',
                         'X-Auth-Token' => auth_token},
            :method  => 'GET'
          })
      body = Fog::JSON.decode(response.body)
      body['environments']
    end

    def edit_plan_environments(plan_name, environments)
      uri = "#{base_tripleo_api_url}/plans/#{plan_name}/environments"
      response = Fog::Core::Connection.new(uri, false).request({
            :expects => 200,
            :headers => {'Content-Type' => 'application/json',
                         'Accept' => 'application/json',
                         'X-Auth-Token' => auth_token},
            :method  => 'PATCH',
            :body => Fog::JSON.encode(environments),
          })
    end

    ## MISCELLANEOUS PLAN ACTIONS

    def get_plan_deployment_roles(plan_name)
      uri = "#{base_tripleo_api_url}/plans/#{plan_name}/roles"
      response = Fog::Core::Connection.new(uri, false).request({
            :expects => 200,
            :headers => {'Content-Type' => 'application/json',
                         'Accept' => 'application/json',
                         'X-Auth-Token' => auth_token},
            :method  => 'GET'
          })
      body = Fog::JSON.decode(response.body)
      body['roles']
    end

    def get_plan_resource_types(plan_name)
      uri = "#{base_tripleo_api_url}/plans/#{plan_name}/resource_types"
      response = Fog::Core::Connection.new(uri, false).request({
            :expects => 200,
            :headers => {'Content-Type' => 'application/json',
                         'Accept' => 'application/json',
                         'X-Auth-Token' => auth_token},
            :method  => 'GET'
          })
      body = Fog::JSON.decode(response.body)
      body['resource_types']
    end

    ## HEAT ACTIONS

    def list_stacks
      service('Orchestration').stacks.all
    end
    
    def get_stack_by_name(stack_name)
      list_stacks.find{|s| s.stack_name == stack_name}
    end

    private
    
    def base_tripleo_api_url
      return "http://#{@auth_url}:8585/v1"
    end

  end
end
