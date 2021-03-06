require 'spec_helper'
require 'fileutils'

describe Restapi::RestapisController do

  describe "GET index" do

    it "test if route exists" do
      get :index

      assert_response :success
    end

  end

  describe "reload_controllers" do

    RSpec::Matchers.define :reload_documentation do
      match do
        begin
          orig = Restapi.get_resource_description("users")._short_description.dup
          Restapi.get_resource_description("users")._short_description << 'Modified'
          get :index
          ret = Restapi.get_resource_description("users")._short_description == orig
        ensure
          Restapi.get_resource_description("users")._short_description.gsub!('Modified', "")
        end
      end

      failure_message_for_should { "the documentation expected to be reloaded but it was not" }
      failure_message_for_should_not { "the documentation expected not to be reloaded but it was" }
    end

    before do
      Restapi.configuration.api_controllers_matcher = File.join(Rails.root, "app", "controllers", "**","*.rb")
      if Restapi.configuration.send :instance_variable_defined?, "@reload_controllers"
        Restapi.configuration.send :remove_instance_variable, "@reload_controllers"
      end
    end

    context "it's not specified explicitly" do
      context "and it's in development environment" do
        before do
          Rails.stub(:env => mock(:development? => true))
        end
        it { should reload_documentation }
      end

      context "and it's not development environment" do
        it { should_not reload_documentation }
      end
    end


    context "it's explicitly enabled" do
      before do
        Restapi.configuration.reload_controllers = true
      end

      context "and it's in development environment" do
        before do
          Rails.stub(:env => mock(:development? => true))
        end
        it { should reload_documentation }
      end

      context "and it's not development environment" do
        it { should reload_documentation }
      end
    end

    context "it's explicitly enabled" do
      before do
        Restapi.configuration.reload_controllers = false
      end

      context "and it's in development environment" do
        before do
          Rails.stub(:env => mock(:development? => true))
        end
        it { should_not reload_documentation }
      end

      context "and it's not development environment" do
        it { should_not reload_documentation }
      end
    end

    context "api_controllers_matcher is specified" do
      before do
        Restapi.configuration.reload_controllers = true
        Restapi.configuration.api_controllers_matcher = nil
      end

      it { should_not reload_documentation }
    end
  end

  describe "documentation cache" do

    let(:cache_dir) { File.join(Rails.root, "tmp", "restapi-cache") }

    before do
      FileUtils.rm_r(cache_dir) if File.exists?(cache_dir)
      FileUtils.mkdir_p(File.join(cache_dir, "apidoc", "resource"))
      File.open(File.join(cache_dir, "apidoc.html"), "w") { |f| f << "apidoc.html cache" }
      File.open(File.join(cache_dir, "apidoc.json"), "w") { |f| f << "apidoc.json cache" }
      File.open(File.join(cache_dir, "apidoc", "resource.html"), "w") { |f| f << "resource.html cache" }
      File.open(File.join(cache_dir, "apidoc", "resource", "method.html"), "w") { |f| f << "method.html cache" }

      Restapi.configuration.use_cache = true
      Restapi.configuration.cache_dir = cache_dir
    end

    after do
      FileUtils.rm_r(cache_dir) if File.exists?(cache_dir)
    end

    it "uses the file in cache dir instead of generating the content on runtime" do
      get :index
      response.body.should == "apidoc.html cache"
      get :index, :format => "html"
      response.body.should == "apidoc.html cache"
      get :index, :format => "json"
      response.body.should == "apidoc.json cache"
      get :index, :format => "html", :resource => "resource"
      response.body.should == "resource.html cache"
      get :index, :format => "html", :resource => "resource", :method => "method"
      response.body.should == "method.html cache"
    end

  end
end
