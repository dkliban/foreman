module Foreman::Model
  class Imgfac < ComputeResource
    validates :user, :password, :presence => true

    def provided_attributes
      super.merge({ :ip => :floating_ip_address })
    end

    def self.model_name
      ComputeResource.model_name
    end

    def image_param_name
      :image_ref
    end

    def capabilities
      [:image]
    end

    def test_connection options = {}
      super
      errors[:user].empty? and errors[:password] and tenants
    rescue => e
      errors[:base] << e.message
    end

    def available_images
      {}
      #client.images
    end

    def create_vm(args = {})
      network = args.delete(:network)
      vm      = super(args)
      if network.present?
        address = allocate_address(network)
        assign_floating_ip(address, vm)
      end
      vm
    rescue => e
      message = JSON.parse(e.response.body)['badRequest']['message'] rescue (e.to_s)
      logger.warn "failed to create vm: #{message}"
      destroy_vm vm.id if vm
      raise message
    end

    def destroy_vm uuid
      vm           = find_vm_by_uuid(uuid)
      floating_ips = vm.all_addresses
      floating_ips.each do |address|
        client.disassociate_address(uuid, address['ip']) rescue true
        client.release_address(address['id']) rescue true
      end
      super(uuid)
    rescue ActiveRecord::RecordNotFound
      # if the VM does not exists, we don't really care.
      true
    end

    def console(uuid)
      vm = find_vm_by_uuid(uuid)
      vm.console.body.merge({'timestamp' => Time.now.utc})
    end

    def associated_host(vm)
      Host.authorized(:view_hosts, Host).where(:ip => [vm.floating_ip_address, vm.private_ip_address]).first
    end

    def self.provider_friendly_name
      "Image Factory"
    end

    private

    def client
      @client = RestClient
    end

    def vm_instance_defaults
      super.merge(
        :key_name  => key_pair.name
      )
    end

  end
end
