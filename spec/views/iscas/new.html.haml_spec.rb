require 'rails_helper'

RSpec.describe "iscas/new", type: :view do
  before(:each) do
    assign(:isca, Isca.new())
  end

  it "renders new isca form" do
    render

    assert_select "form[action=?][method=?]", iscas_path, "post" do
    end
  end
end
