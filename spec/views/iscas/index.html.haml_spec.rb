require 'rails_helper'

RSpec.describe "iscas/index", type: :view do
  before(:each) do
    assign(:iscas, [
      Isca.create!(),
      Isca.create!()
    ])
  end

  it "renders a list of iscas" do
    render
  end
end
