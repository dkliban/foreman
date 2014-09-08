class Image < ActiveRecord::Base
  include Authorizable
  
  before_validation :check_compute_resource

  audited :allow_mass_assignment => true

  belongs_to :operatingsystem
  belongs_to :compute_resource
  belongs_to :architecture

  has_many_hosts :dependent => :nullify

  validates_lengths_from_database
  validates :username, :name, :operatingsystem_id, :compute_resource_id, :architecture_id, :presence => true
  validates :uuid, :presence => true, :uniqueness => {:scope => :compute_resource_id}

  scoped_search :on => [:name, :username], :complete_value => true
  scoped_search :in => :compute_resources, :on => :name, :complete_value => :true, :rename => "compute_resource"
  scoped_search :in => :architecture, :on => :id, :rename => "architecture"
  scoped_search :in => :operatingsystem, :on => :id, :rename => "operatingsystem"
  scoped_search :on => :user_data, :complete_value => {:true => true, :false => false}

  def check_compute_resource
    # Only do this for the Image Factory compute resource images
    if compute_resource.type == "Foreman::Model::Imgfac"
      begin
        url = compute_resource.url + "/imagefactory/base_images"
        body = '{"base_image": {"template":"<template><name>buildbase_image</name><os><name>MockOS_A</name><version>1</version><arch>x86_64</arch><install type=\'url\'><url>http://download.devel.redhat.com/released/F-17/GOLD/Fedora/x86_64/os/</url></install><rootpw>password</rootpw></os><description>Tests building a base_image</description></template>"}}'
        debugger
        response = JSON.load(RestClient.post url, body, :content_type => :json, :accept => :json)
        self.uuid = response['base_image']['id'] 
      rescue => e
        errors.add(:base, e.message)
        return false 
      end
    end
  end
end
