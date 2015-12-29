require 'rails_helper'

RSpec.describe "iscas/show", type: :view do
  before(:each) do
    @isca = assign(:isca, Isca.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
