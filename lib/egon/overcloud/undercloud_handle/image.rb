module Overcloud
  module Image

    def list_images
      service('Image').images
    end

    def find_image_by_name(image_name)
      service('Image').images.find{|image| image.name == image_name}
    end

    def get_baremetal_deploy_kernel_image
      find_image_by_name('bm-deploy-kernel')
    end

    def get_baremetal_deploy_ramdisk_image
      find_image_by_name('bm-deploy-ramdisk')
    end
  end
end
