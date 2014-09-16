class ImageStoresController < ApplicationController
  include Foreman::Controller::AutoCompleteSearch
  AJAX_REQUESTS = %w{template_selected cluster_selected}
  before_filter :ajax_request, :only => AJAX_REQUESTS
  before_filter :find_by_name, :only => [:show, :edit, :associate, :update, :destroy, :ping] + AJAX_REQUESTS

  #This can happen in development when removing a plugin
  rescue_from ActiveRecord::SubclassNotFound do |e|
    type = (e.to_s =~ /failed to locate the subclass: '((\w|::)+)'/) ? $1 : 'STI-Type'
    render :text => (e.to_s+"<br><b>run ImageStore.delete_all(:type=>'#{type}') to recover.</b>").html_safe, :status=> 500
  end

  def index
    @image_stores = resource_base.live_descendants.search_for(params[:search], :order => params[:order]).paginate :page => params[:page]
  end

  def new
    @image_store = ImageStore.new
  end

  def show
  end

  def create
    if params[:image_store].present? && params[:image_store][:provider].present?
      @image_store = ImageStore.new_provider params[:image_store]
      if @image_store.save
        # Add the new compute resource to the user's filters
        process_success :success_redirect => @image_store
      else
        process_error
      end
    else
      @image_store = ImageStore.new params[:image_store]
      @image_store.valid?
      process_error
    end
  end

  def edit
  end

  def update
    params[:image_store].except!(:password) if params[:image_store][:password].blank?
    if @image_store.update_attributes(params[:image_store])
      process_success
    else
      process_error
    end
  end

  def destroy
    if @image_store.destroy
      process_success
    else
      process_error
    end
  end

  #ajax methods
  def provider_selected
    @image_store = ImageStore.new_provider :provider => params[:provider]
    render :partial => "image_stores/form", :locals => { :image_store => @image_store }
  end

  def template_selected
    compute = @image_store.template(params[:template_id])
    respond_to do |format|
      format.json { render :json => compute }
    end
  end

end
