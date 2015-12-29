require 'rails_helper'

RSpec.describe "Iscas", type: :request do
  describe "GET /iscas" do
    it "works! (now write some real specs)" do
      get iscas_path
      expect(response).to have_http_status(200)
    end
  end
end
