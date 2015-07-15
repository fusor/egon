module Overcloud
  module Deployment
 
    def get_plan(plan_name)
      service('Planning').plans.find_by_name(plan_name)
    end

    def edit_plan_parameters(plan_name, parameters)
      get_plan(plan_name).patch(:parameters => parameters)
    end

    def edit_plan_deployment_role_count(plan_name, role_name, count)
      parameter = {"name" => role_name + "-1::count", "value" => count.to_s}
      edit_plan_parameters(plan_name, [parameter])
    end

    def edit_plan_deployment_role_image(plan_name, role_name, image_uuid)
      parameter = {"name" => role_name + "-1::Image", "value" => image_uuid}
      edit_plan_parameters([parameter])
    end

    def edit_plan_deployment_role_flavor(plan_name, role_name, flavor_name)
      parameter = {"name" => role_name + "-1::Flavor", "value" => flavor_name}
      edit_plan_parameters(plan_name, [parameter])
    end

    def deploy_plan(plan_name)
      # ensure that nodes are in correct state
      for node in list_nodes
        node.set_provision_state('provide') if node.provision_state == 'manageable'
      end

      plan = get_plan(plan_name)
      templates = Hash[plan.provider_resource_templates]

      # temporary workaround for https://bugzilla.redhat.com/show_bug.cgi?id=1212740
      templates.keys.each do |template_path|
        if template_path.index('puppet/') == 0
          new_template_path = template_path.sub('puppet/','')
          templates[new_template_path] = templates[template_path]
        end
      end
      templates["hieradata/RedHat.yaml"] = templates["puppet/hieradata/RedHat.yaml"]
      templates["yum_update.sh"] = templates["extraconfig/tasks/yum_update.sh"]

      stack_parameters = {
        :stack_name => plan.name,
        :template => plan.master_template,
        :environment => plan.environment,
        :files => templates,
        :password => @password,
        :timeout_mins => 60,
        :disable_rollback => true
      }
      service('Orchestration').stacks.new.save(stack_parameters)
    end

    def list_stacks
      service('Orchestration').stacks.all
    end
    
    def get_stack_by_name(stack_name)
      list_stacks.find{|s| s.stack_name == stack_name}
    end
  
  end
end
