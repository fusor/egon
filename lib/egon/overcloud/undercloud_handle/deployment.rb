module Overcloud
  module Deployment

    # BASE PLAN ACTIONS

    def list_plans
      return workflow_action_execution('tripleo.plan.list')
    end
 
    def get_plan(plan_name)
      # this doesn't exist anymore?
      return {'name' => plan_name}
    end

    def deploy_plan(plan_name)
      # ensure that nodes are in correct state
      for node in list_nodes
        node.set_provision_state('provide') if node.provision_state == 'manageable'
      end

      workflow = 'tripleo.deployment.v1.deploy_plan'
      input = { container: plan_name }
      execute_workflow(workflow, input, false)
    end

    ## PLAN PARAMETER METHODS

    def get_plan_parameters(plan_name)
      all_params = workflow_action_execution('tripleo.parameters.get', { :container => plan_name })
      return flatten_parameters(all_params["heat_resource_tree"])
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
      action_parameters = {
        :container => plan_name,
        :parameters => parameters
      }
      workflow_action_execution('tripleo.parameters.update', action_parameters)
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
      return workflow_action_execution('tripleo.heat_capabilities.get', { :container => plan_name })
    end

    def edit_plan_environments(plan_name, environments)
      action_parameters = {
        :container => plan_name,
        :environments => environments
      }
      workflow_action_execution('tripleo.heat_capabilities.update', action_parameters)
    end

    ## MISCELLANEOUS PLAN ACTIONS

    def get_plan_deployment_roles(plan_name)
      return workflow_action_execution('tripleo.role.list', { :container => plan_name })
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
    
    def flatten_parameters(base_parameters)
      flat_parameters = {}
      if base_parameters.key?('Parameters')
        flat_parameters.merge!base_parameters['Parameters']
      end
      if base_parameters.key?('NestedParameters')
        for nested_parameters in base_parameters['NestedParameters']
          flat_parameters.merge!(flatten_parameters(nested_parameters[1]))
        end
      end
      flat_parameters
    end

  end
end
