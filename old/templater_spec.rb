require 'spec_helper'

describe Templater do
  describe "render_template" do
    it "should render out a haml template when given a file that has a div" do
      template = Templater.render_template(:test, path: "/spec/support")
      template.should include("div")
    end
  end
end
