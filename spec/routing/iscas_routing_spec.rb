require "rails_helper"

RSpec.describe IscasController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/iscas").to route_to("iscas#index")
    end

    it "routes to #new" do
      expect(:get => "/iscas/new").to route_to("iscas#new")
    end

    it "routes to #show" do
      expect(:get => "/iscas/1").to route_to("iscas#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/iscas/1/edit").to route_to("iscas#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/iscas").to route_to("iscas#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/iscas/1").to route_to("iscas#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/iscas/1").to route_to("iscas#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/iscas/1").to route_to("iscas#destroy", :id => "1")
    end

  end
end
