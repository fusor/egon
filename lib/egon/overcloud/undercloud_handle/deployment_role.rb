module Overcloud
  module DeploymentRole

    def list_deployment_roles
      service('Planning').roles
    end

  end
end
