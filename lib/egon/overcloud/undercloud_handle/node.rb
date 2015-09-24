require_relative 'flavor'
require 'csv'
require 'timeout'

module Overcloud
  module Node
    
    def list_nodes
      service('Baremetal').nodes.details
    end

    def get_node(node_id)
      service('Baremetal').nodes.find_by_uuid(node_id)
    end
    
    def create_node(node_parameters, create_flavor = false)
      node = service('Baremetal').nodes.create(node_parameters)
      create_port({:node_uuid => node.uuid, :address => node_parameters[:address]})

      node.set_provision_state('manage')
      introspect_node(node.uuid)
      node
    end

    def create_port(port_parameters)
      service('Baremetal').ports.create(port_parameters)
    end

    def create_nodes_from_csv(csv_file, create_flavor = false)
      CSV.foreach(csv_file) do |node_data|
        memory_mb = node_data[0]
        local_gb = node_data[1]
        cpus = node_data[2]
        cpu_arch = node_data[3]
        driver = node_data[4]
        mac_address = node_data[8]
        if driver == 'pxe_ssh'
          driver_info = {
            :ssh_address => node_data[5],
            :ssh_username => node_data[6],
            :ssh_key_contents => node_data[7],
            :ssh_virt_type => 'virsh',
            :deploy_kernel => get_baremetal_deploy_kernel_image.id,
            :deploy_ramdisk => get_baremetal_deploy_ramdisk_image.id
          }
        elsif driver == 'pxe_ipmitool'
          driver_info = {
            :ipmi_address => node_data[5],
            :ipmi_username => node_data[6],
            :ipmi_password => node_data[7],
            :pxe_deploy_kernel => get_baremetal_deploy_kernel_image.id,
            :pxe_deploy_ramdisk => get_baremetal_deploy_ramdisk_image.id
          }
        else
          raise "Unknown node driver: #{driver}"
        end

        node_parameters = {
          :driver => driver,
          :driver_info => driver_info,
          :properties => {
            :cpus => cpus,
            :memory_mb => memory_mb,
            :local_gb => local_gb,
            :cpu_arch => cpu_arch,
            :capabilities => 'boot_option:local'
          },
          :address => mac_address
        }
        node = create_node(node_parameters, create_flavor)
      end
    end

    ## THESE METHODS ARE TEMPORARY UNTIL IRONIC-DISCOVERD IS ADDED TO
    ## OPENSTACK AND KEYSTONE

    def introspect_node(node_uuid)
      uri = "http://#{@auth_url}:5050/v1/introspection/#{node_uuid}"
      auth_token = service('Baremetal').instance_variable_get(:@auth_token)
      response = Fog::Core::Connection.new(uri, false).request({
            :expects => 202,
            :headers => {'Content-Type' => 'application/json',
                         'Accept' => 'application/json',
                         'X-Auth-Token' => auth_token},
            :method  => 'POST'
          })      
    end

    def introspect_node_status(node_uuid)
      uri = "http://#{@auth_url}:5050/v1/introspection/#{node_uuid}"
      auth_token = service('Baremetal').instance_variable_get(:@auth_token)
      response = Fog::Core::Connection.new(uri, false).request({
            :expects => 200,
            :headers => {'Content-Type' => 'application/json',
                         'Accept' => 'application/json',
                         'X-Auth-Token' => auth_token},
            :method  => 'GET'
          })
      Fog::JSON.decode(response.body)['finished']
    end

  end
end
