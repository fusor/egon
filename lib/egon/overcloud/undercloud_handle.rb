require 'fog/openstack'
require 'json'
require_relative 'undercloud_handle/deployment'
require_relative 'undercloud_handle/flavor'
require_relative 'undercloud_handle/image'
require_relative 'undercloud_handle/node'

module Overcloud
  class UndercloudHandle

    include Overcloud::Deployment
    include Overcloud::Flavor
    include Overcloud::Image
    include Overcloud::Node

    def initialize(username, password, auth_url, port = 5000)
      @username = username
      @password = password
      @auth_url = auth_url
      @port = port
    end

    def execute_workflow(workflow, input, wait_for_complete = true)
      connection = service('Workflow')
      response = connection.create_execution(workflow, input)
      state = response.body['state']
      workflow_execution_id = response.body['id']

      return unless wait_for_complete

      while state == 'RUNNING'
        sleep 2
        response = connection.get_execution(workflow_execution_id)
        state = response.body['state']
      end

      if state != 'SUCCESS'
        raise "Executing workflow #{workflow} on #{input} failed: #{response.body['output']}"
      end
      workflow_execution_id
    end

    def workflow_action_execution(action_name, params = {})
      return JSON.parse(service('Workflow').create_action_execution(action_name, params).body["output"])["result"]
    end

    private
    
    def service(service_name)
      fog_parameters = {
        :provider           => 'OpenStack',
        :openstack_auth_url => 'http://' + @auth_url + ':' + @port.to_s + '/v2.0/tokens',   
        :openstack_username => @username,
        :openstack_api_key  => @password,
        :openstack_tenant   => @username,
      }
      
      if service_name == 'Planning'
        return Fog::Openstack.const_get(service_name).new(fog_parameters)
      elsif service_name == 'Workflow'
        return Fog::Workflow::OpenStack.new(fog_parameters)
      end
      return Fog.const_get(service_name).new(fog_parameters)
    end

    def auth_token
      service('Baremetal').instance_variable_get(:@auth_token)
    end

  end
end
