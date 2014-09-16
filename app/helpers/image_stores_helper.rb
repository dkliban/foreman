module ImageStoresHelper
  include LookupKeysHelper

  def list_providers
    ImageStore.providers.map do |provider|
      [ImageStore.provider_class(provider).constantize.provider_friendly_name, provider]
    end
  end

end
