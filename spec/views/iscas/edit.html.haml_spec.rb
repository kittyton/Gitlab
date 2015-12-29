require 'rails_helper'

RSpec.describe "iscas/edit", type: :view do
  before(:each) do
    @isca = assign(:isca, Isca.create!())
  end

  it "renders the edit isca form" do
    render

    assert_select "form[action=?][method=?]", isca_path(@isca), "post" do
    end
  end
end
