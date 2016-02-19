require 'fog'
require 'fog/openstack/models/baremetal/nodes'
require 'fog/openstack/models/compute/flavors'
require 'fog/openstack/models/image_v1/image'
require 'fog/openstack/models/orchestration/stacks'
require 'fog/openstack/models/planning/plans'
require 'fog/openstack/models/planning/role'
require './lib/egon/overcloud/undercloud_handle'

describe "overcloud installation mocked" do
  context "undercloud handle" do
    before(:each) do
      options = {
        :openstack_username => 'user',
        :openstack_tenant => 'tenant',
        :openstack_auth_url => 'http://194.0.0.0'
      }
      @undercloud_handle = Overcloud::UndercloudHandle.new(options[:openstack_username], 'xxxxxxx', options[:openstack_auth_url])

      # setup for mock image service
      image_service = Fog::Image::OpenStack::V1::Mock.new(options)
      bm_deploy_kernel_image = Fog::Image::OpenStack::V1::Image.new({
        :id => '1',
        :name => 'bm-deploy-kernel'
      })
      bm_deploy_ramdisk_image = Fog::Image::OpenStack::V1::Image.new({
        :id => '2',
        :name => 'bm-deploy-ramdisk'
      })
      allow(image_service).to receive(:images).and_return([bm_deploy_kernel_image, bm_deploy_ramdisk_image])
      allow(@undercloud_handle).to receive(:service).with('Image').and_return(image_service)

      # setup for mock baremetal service
      baremetal_service = Fog::Baremetal::OpenStack::Mock.new(options)
      nodes = Fog::Baremetal::OpenStack::Nodes.new
      node1 = Fog::Baremetal::OpenStack::Node.new({
        'id' => '1',
        'properties' => {
           'cpus' => '1',
           'memory_mb' => '4096',
           'local_gb' => '40',
           'cpu_arch' => 'x86_64'
        },
      })
      node2 = Fog::Baremetal::OpenStack::Node.new({
        'id' => '2',
        'properties' => {
           'cpus' => '1',
           'memory_mb' => '5012',
           'local_gb' => '40',
           'cpu_arch' => 'x86_64'
        },
      })
      allow(nodes).to receive(:details).and_return([node1, node2])
      allow(baremetal_service).to receive(:nodes).and_return(nodes)
      allow(@undercloud_handle).to receive(:service).with('Baremetal').and_return(baremetal_service)

      # setup for mock compute service
      compute_service = Fog::Compute::OpenStack::Mock.new(options)
      flavors = Fog::Compute::OpenStack::Flavors.new
      baremetal_flavor = Fog::Compute::OpenStack::Flavor.new({
        'id' => '1',
        'name' => 'baremetal',
        'disk' => 40,
        'ram' => 4096,
        'vcpus' => 1,
      })
      allow(baremetal_flavor).to receive(:metadata).and_return({'cpu_arch' => 'x86_64'})
      allow(flavors).to receive(:all).and_return([baremetal_flavor])
      allow(flavors).to receive(:get).and_return(baremetal_flavor)
      allow(compute_service).to receive(:flavors).and_return(flavors)
      allow(@undercloud_handle).to receive(:service).with('Compute').and_return(compute_service)

      # setup for mock planning service
      planning_service = Fog::Openstack::Planning::Mock.new(options)
      plans = Fog::Openstack::Planning::Plans.new
      overcloud_plan = Fog::Openstack::Planning::Plan.new({
        :uuid => '1',
        :name => 'overcloud'
      })
      compute_role = Fog::Openstack::Planning::Role.new({
        :uuid => '1',
        :name => 'Compute'
      })
      controller_role = Fog::Openstack::Planning::Role.new({
        :uuid => '1',
        :name => 'Controller'
      })
      allow(planning_service).to receive(:roles).and_return([compute_role, controller_role])
      allow(planning_service).to receive(:plans).and_return(plans)
      allow(plans).to receive(:find_by_name).and_return(overcloud_plan)
      allow(@undercloud_handle).to receive(:service).with('Planning').and_return(planning_service)

      # setup for mock orchestration service
      orchestration_service = Fog::Orchestration::OpenStack::Mock.new(options)
      stacks = Fog::Orchestration::OpenStack::Stacks.new
      overcloud_stack = Fog::Orchestration::OpenStack::Stack.new({
        'id' => '1',
        'name' => 'overcloud',
      })
      allow(stacks).to receive(:get).and_return(overcloud_stack)
      allow(orchestration_service).to receive(:stacks).and_return(stacks)
      allow(@undercloud_handle).to receive(:service).with('Orchestration').and_return(orchestration_service)
    end

    it "should be able to list_images" do
      expect(@undercloud_handle.list_images.length).to eq 2
    end

    it "should be able to find_image_by_name" do
      expect(@undercloud_handle.find_image_by_name('bm-deploy-kernel').id).to eq '1'
    end

    it "should be able to get_baremetal_deploy_kernel_image" do
      expect(@undercloud_handle.find_image_by_name('bm-deploy-kernel').id).to eq '1'
    end

    it "should be able to get_baremetal_deploy_ramdisk_image" do
      expect(@undercloud_handle.find_image_by_name('bm-deploy-ramdisk').id).to eq '2'
    end

    it "should be able to list_flavors" do
      expect(@undercloud_handle.list_flavors.length).to eq 1
    end

    it "should be able to get_flavor" do
      expect(@undercloud_handle.get_flavor('1').name).to eq 'baremetal'
    end

    it "should be able to get_flavor_extra_specs" do
      expect(@undercloud_handle.get_flavor_extra_specs('1')['cpu_arch']).to eq 'x86_64'
    end

    it "should return true if flavor_exists? matches a flavor" do
      flavor_parameters = {
        :disk => 40,
        :ram => 4096,
        :vcpus => 1,
        :extra_specs => {
          :cpu_arch => 'x86_64'
        }
      }
      expect(@undercloud_handle.flavor_exists?(flavor_parameters)).to be true
    end

    it "should return false if flavor_exists? does not match a flavor" do
      flavor_parameters = {
        :disk => 40,
        :ram => 5012,
        :vcpus => 1,
        :extra_specs => {
          :cpu_arch => 'x86_64'
        }
      }
      expect(@undercloud_handle.flavor_exists?(flavor_parameters)).to be false
    end

    it "should not create_flavor_from_from_node if matching flavor exists" do
      node = @undercloud_handle.list_nodes[0]
      expect(@undercloud_handle.create_flavor_from_node(node)).to be_nil
    end

    it "should be able to list_nodes" do
      expect(@undercloud_handle.list_nodes.length).to eq 2
    end

    it "should be able to list_deployment_roles" do
      expect(@undercloud_handle.list_deployment_roles.length).to eq 2
    end

    it "should be able to get_plan" do
      expect(@undercloud_handle.get_plan('overcloud').uuid).to eq '1'
    end

    it "should be able to get_stack" do
      expect(@undercloud_handle.get_stack('overcloud').id).to eq '1'
    end
  end
end
