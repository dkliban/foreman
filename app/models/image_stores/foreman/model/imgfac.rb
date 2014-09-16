module Foreman::Model
  class Imgfac < ImageStore
    validates :url, :presence => true

    def self.model_name
      ImageStore.model_name
    end

    def image_param_name
      :image_ref
    end

    def capabilities
      [:image]
    end

    def available_images
      {}
    end

    def self.provider_friendly_name
      "Image Factory"
    end

    private

    def client
      @client = RestClient
    end

  end
end
