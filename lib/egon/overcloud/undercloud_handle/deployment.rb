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

      uri = "#{base_tripleo_api_url}/plans/#{plan_name}/deploy"
      response = Fog::Core::Connection.new(uri, false).request({
            :expects => 202,
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
            :method  => 'GET',
            :read_timeout => 360,
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
            :read_timeout => 360,
            :write_timeout => 360,
          })
    end

    def edit_plan_deployment_role_count(plan_name, role_name, count)
      parameters = {role_name + "Count" => count.to_s}
      edit_plan_parameters(plan_name, parameters)
    end

    def edit_plan_deployment_role_flavor(plan_name, role_name, flavor_name)
      if role_name == 'Controller'
          flavor_parameter = 'OvercloudControlFlavor'
      else
          flavor_parameter = 'Overcloud' + role_name + 'Flavor'
      end
      parameters = {flavor_parameter => flavor_name}
      edit_plan_parameters(plan_name, parameters)
    end

    ## PLAN ENVIRONMENT ACTIONS

    def get_plan_environments(plan_name)
      uri = "#{base_tripleo_api_url}/plans/#{plan_name}/environments"
      response = Fog::Core::Connection.new(uri, false).request({
            :expects => 200,
            :headers => {'Content-Type' => 'application/json',
                         'Accept' => 'application/json',
                         'X-Auth-Token' => auth_token},
            :method  => 'GET',
            :read_timeout => 360,
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
            :read_timeout => 360,
            :write_timeout => 360,
          })
    end

    ## MISCELLANEOUS PLAN ACTIONS

    def get_plan_deployment_roles(plan_name)
      # temporarily hard-coded until API adds role function
      return ['Controller', 'Compute', 'BlockStorage', 'ObjectStorage',
              'CephStorage']

      #uri = "#{base_tripleo_api_url}/plans/#{plan_name}/roles"
      #response = Fog::Core::Connection.new(uri, false).request({
      #      :expects => 200,
      #      :headers => {'Content-Type' => 'application/json',
      #                   'Accept' => 'application/json',
      #                   'X-Auth-Token' => auth_token},
      #      :method  => 'GET'
      #    })
      #body = Fog::JSON.decode(response.body)
      #body['roles']
    end

    ## HEAT ACTIONS

    def list_stacks
      service('Orchestration').stacks.all
    end
    
    def get_stack_by_name(stack_name)
      list_stacks.find{|s| s.stack_name == stack_name}
    end

    def delete_stack(overcloud)
      service('Orchestration').delete_stack(overcloud)
    end

    private
    
    def base_tripleo_api_url
      return "http://#{@auth_url}:8585/v1"
    end

  end
end
