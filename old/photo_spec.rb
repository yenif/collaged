require 'spec_helper'

describe Photo do
  it 'should calculate the correct default dimensions for tall images' do
    p = Collage.create.photos.new
    p.image_height = 100
    p.image_width = 1

    p.size = 16

    p.save

    p.height.should == 16
    p.width.should == 1
  end

  it 'should calculate the correct default dimensions for wide images' do
    p = Collage.create.photos.new
    p.image_height = 1
    p.image_width = 100

    p.size = 16

    p.save

    p.height.should == 1
    p.width.should == 16
  end
end
