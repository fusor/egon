require 'fog'
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
      end
      return Fog.const_get(service_name).new(fog_parameters)
    end

    def auth_token
      service('Baremetal').instance_variable_get(:@auth_token)
    end

  end
end
