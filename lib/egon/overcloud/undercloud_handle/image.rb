module Overcloud
  module Image

    def list_images
      service('Image').images
    end

  end
end
