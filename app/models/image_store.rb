class ImageStore < ActiveRecord::Base
  include Taxonomix
  include Encryptable

  class_attribute :supported_providers
  self.supported_providers = {
    'Imgfac'    => 'Foreman::Model::Imgfac',
  }

  validates_lengths_from_database

  audited :except => [:attrs], :allow_mass_assignment => true
  has_many :trends, :as => :trendable, :class_name => "ForemanTrend"

  before_destroy EnsureNotUsedBy.new(:hosts)
  validates :name, :presence => true, :uniqueness => true,
            :format => { :with => /\A(\S+)\Z/, :message => N_("can't contain white spaces.") }
  validates :provider, :presence => true, :inclusion => { :in => proc { self.providers } }
  validates :url, :presence => true
  scoped_search :on => :name, :complete_value => :true
  scoped_search :on => :type, :complete_value => :true
  scoped_search :on => :id, :complete_value => :true
  before_save :sanitize_url
  has_many_hosts
  has_many :images, :dependent => :destroy

  # The DB may contain compute resource from disabled plugins - filter them out here
  scope :live_descendants, lambda { where(:type => self.descendants.map(&:to_s)) unless Rails.env.development? }

  # with proc support, default_scope can no longer be chained
  # include all default scoping here
  default_scope lambda {
    with_taxonomy_scope do
      order("image_stores.name")
    end
  }

  def self.register_provider(provider)
    name = provider.name.split('::').last
    return if supported_providers.values.include?(provider) || supported_providers.keys.include?(name)
    supported_providers[name] = provider.name
  end

  def self.providers
    supported_providers.reject { |p,c| !SETTINGS[p.downcase.to_sym] }.keys
  end

  def self.provider_class(name)
    supported_providers[name]
  end

  # allows to create a specific compute class based on the provider.
  def self.new_provider args
    raise ::Foreman::Exception.new(N_("must provide a provider")) unless provider = args.delete(:provider)
    self.providers.each do |p|
      return self.provider_class(p).constantize.new(args) if p.downcase == provider.downcase
    end
    raise ::Foreman::Exception.new N_("unknown provider")
  end

  def capabilities
    []
  end

  # attributes that this provider can provide back to the host object
  def provided_attributes
    {:uuid => :identity}
  end

  def to_param
    "#{id}-#{name.parameterize}"
  end

  def to_label
    "#{name} (#{provider_friendly_name})"
  end

  # Override this method to specify provider name
  def self.provider_friendly_name
    self.name.split('::').last()
  end

  def provider_friendly_name
    self.class.provider_friendly_name
  end

  def image_param_name
    :image_id
  end


  def provider
    read_attribute(:type).to_s.split('::').last
  end

  def provider=(value)
    if self.class.providers.include? value
      self.type = self.class.provider_class(value)
    else
      raise ::Foreman::Exception.new N_("unknown provider")
    end
  end

  def templates(opts={})
  end

  def template(id,opts={})
  end

  def available_images
    []
  end

  protected

  def client
    raise ::Foreman::Exception.new N_("Not implemented")
  end

  def sanitize_url
    self.url.chomp!("/") unless url.empty?
  end

end
