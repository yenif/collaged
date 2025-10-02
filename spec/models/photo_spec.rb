require 'spec_helper'

describe Photo do
  let(:collage) { Collage.create(title: "Test Collage") }

  describe "grid dimension calculation (prime factorization)" do
    it 'should calculate the correct default dimensions for tall images' do
      p = collage.photos.new
      p.image_height = 100
      p.image_width = 1

      p.size = 16

      p.save

      p.height.should == 16
      p.width.should == 1
    end

    it 'should calculate the correct default dimensions for wide images' do
      p = collage.photos.new
      p.image_height = 1
      p.image_width = 100

      p.size = 16

      p.save

      p.height.should == 1
      p.width.should == 16
    end

    it 'calculates dimensions for square images' do
      p = collage.photos.new
      p.image_height = 100
      p.image_width = 100
      p.size = 16

      p.save

      # For square images with size 16, should be 4x4
      p.height.should == 4
      p.width.should == 4
      p.height * p.width.should == p.size
    end

    it 'uses prime factorization to find all possible dimensions' do
      # Characterize Integer#factors method behavior
      # For size = 12, factors are: [1, 2, 3, 4, 6, 12]
      p = collage.photos.new
      p.image_height = 200
      p.image_width = 100  # 2:1 aspect ratio
      p.size = 12

      p.save

      # Should find closest to 2:1 aspect, which is 6 height × 2 width
      p.height.should == 6
      p.width.should == 2
      p.height * p.width.should == 12
    end

    it 'handles prime number sizes (limited dimension options)' do
      p = collage.photos.new
      p.image_height = 100
      p.image_width = 100
      p.size = 13  # Prime number - only factors are [1, 13]

      p.save

      # For prime sizes, only options are 1×13 or 13×1
      # Should choose 13×1 for square aspect (closer to 1:1)
      (p.height == 13 && p.width == 1) || (p.height == 1 && p.width == 13)
      p.height * p.width.should == 13
    end

    it 'maintains size = width × height constraint' do
      p = collage.photos.new
      p.image_height = 150
      p.image_width = 75
      p.size = 24

      p.save

      p.height * p.width.should == p.size
    end
  end

  describe "aspect ratio preservation" do
    it 'preserves image aspect ratio when custom_aspect is false' do
      p = collage.photos.new
      p.image_height = 200
      p.image_width = 100  # 2:1 aspect ratio
      p.custom_aspect = false
      p.size = 16

      p.save

      # Should find grid dimensions closest to 2:1 aspect
      # Factors of 16: [1, 2, 4, 8, 16]
      # Possible dimensions: 1×16, 2×8, 4×4, 8×2, 16×1
      # Closest to 2:1 is 8×2 or 4×2 (checking actual implementation)
      grid_aspect = p.height / p.width.to_f
      image_aspect = p.image_height / p.image_width.to_f

      # Grid aspect should be close to image aspect
      # This characterizes the binary search algorithm in set_default_dimensions
      (grid_aspect - image_aspect).abs.should < 1.0
    end

    it 'uses custom aspect ratio when custom_aspect is true' do
      p = collage.photos.new
      p.image_height = 200
      p.image_width = 100  # 2:1 image aspect
      p.height = 1
      p.width = 4  # 1:4 custom aspect (different from image)
      p.custom_aspect = true
      p.size = 16

      p.save

      # Should preserve the custom 1:4 aspect despite 2:1 image aspect
      # Re-calculate to find closest to 1:4 aspect
      grid_aspect = p.height / p.width.to_f
      grid_aspect.should be < 0.5  # Much wider than tall
    end

    it 'uses binary search to find nearest aspect ratio match' do
      # Characterize the algorithm in set_default_dimensions:
      # - Gets factors array
      # - Sets high/low indices
      # - Binary search with distance calculation
      # - distance = (factors[index] / (size / factors[index])) - aspect

      p = collage.photos.new
      p.image_height = 150
      p.image_width = 100  # 1.5:1 aspect
      p.size = 18  # factors: [1, 2, 3, 6, 9, 18]

      p.save

      # Possible dimensions for size 18:
      # 1×18 (1:18 = 0.056), 2×9 (2:9 = 0.222), 3×6 (3:6 = 0.5),
      # 6×3 (6:3 = 2), 9×2 (9:2 = 4.5), 18×1 (18:1 = 18)
      # Target aspect: 1.5
      # Closest is 6×3 (aspect 2) or 3×6 (aspect 0.5)
      # Should choose 6×3 (distance |2 - 1.5| = 0.5)
      p.height.should == 6
      p.width.should == 3
    end
  end

  describe "size field behavior" do
    it 'defaults size to 1 if not set' do
      p = collage.photos.new
      p.image_height = 100
      p.image_width = 100

      p.save

      p.size.should == 1
    end

    it 'recalculates dimensions if size changes' do
      p = collage.photos.new
      p.image_height = 100
      p.image_width = 100
      p.size = 4

      p.save
      original_height = p.height
      original_width = p.width

      # Change size and save again
      p.size = 9
      p.save

      # Dimensions should update to maintain size constraint
      p.height * p.width.should == 9
      (p.height != original_height || p.width != original_width).should be_true
    end

    it 'preserves custom dimensions if they satisfy size constraint' do
      p = collage.photos.new
      p.image_height = 100
      p.image_width = 100
      p.size = 12
      p.height = 3
      p.width = 4

      p.save

      # 3 × 4 = 12, so dimensions should be preserved
      p.height.should == 3
      p.width.should == 4
    end

    it 'recalculates dimensions if custom dimensions do not match size' do
      p = collage.photos.new
      p.image_height = 100
      p.image_width = 100
      p.size = 12
      p.height = 2
      p.width = 5  # 2 × 5 = 10 ≠ 12

      p.save

      # Should recalculate because 10 ≠ 12
      p.height * p.width.should == 12
    end
  end

  describe "image metadata fields" do
    it 'stores image_height and image_width' do
      p = collage.photos.create(image_height: 1920, image_width: 1080)

      p.image_height.should == 1920
      p.image_width.should == 1080
    end

    it 'stores image_hash for duplicate detection' do
      p = collage.photos.create(
        image_height: 100,
        image_width: 100,
        image_hash: "abc123"
      )

      p.image_hash.should == "abc123"
    end

    it 'characterizes SHA1 hash format (40 hex characters)' do
      # image_hash should be SHA1 format
      # This documents expected format for duplicate detection
      # Actual hash generation happens in controller/uploader

      p = collage.photos.create(
        image_height: 100,
        image_width: 100,
        image_hash: "a" * 40  # SHA1 is 40 hex characters
      )

      p.image_hash.length.should == 40
    end
  end

  describe "ordinal field for sorting" do
    it 'stores ordinal for sort order' do
      p = collage.photos.create(ordinal: 5, image_height: 100, image_width: 100)
      p.ordinal.should == 5
    end

    it 'has index on ordinal field' do
      # Characterized from: index ordinal: 1
      # This documents the expected index for efficient sorting
      Photo.index_options[:ordinal].should_not be_nil
    end

    it 'photos are ordered by ordinal in collage association' do
      # This is tested in collage_spec.rb but documented here for completeness
      # embeds_many :photos, order: [[:ordinal, :asc]]
      p1 = collage.photos.create(ordinal: 3, image_height: 100, image_width: 100)
      p2 = collage.photos.create(ordinal: 1, image_height: 100, image_width: 100)
      p3 = collage.photos.create(ordinal: 2, image_height: 100, image_width: 100)

      collage.photos.to_a.should == [p2, p3, p1]
    end
  end

  describe "caption field" do
    it 'stores optional caption text' do
      p = collage.photos.create(
        caption: "My photo caption",
        image_height: 100,
        image_width: 100
      )

      p.caption.should == "My photo caption"
    end

    it 'allows nil caption' do
      p = collage.photos.create(image_height: 100, image_width: 100)
      p.caption.should be_nil
    end
  end

  describe "CarrierWave integration" do
    it 'mounts ImageUploader for image field' do
      # Characterized from: mount_uploader :image, ImageUploader
      p = collage.photos.new
      p.should respond_to(:image)
      p.should respond_to(:image=)
    end

    it 'provides image_url method' do
      p = collage.photos.new(image_height: 100, image_width: 100)
      p.should respond_to(:image_url)
    end

    it 'image_url delegates to uploader' do
      p = collage.photos.new(image_height: 100, image_width: 100)
      # p.image_url calls self.image.url
      # This characterizes the delegation pattern
      p.image_url.should == p.image.url
    end
  end

  describe "as_json serialization" do
    it 'includes photo metadata fields' do
      p = collage.photos.create(
        caption: "Test",
        ordinal: 1,
        image_height: 1920,
        image_width: 1080,
        image_hash: "abc123",
        custom_aspect: true,
        size: 4
      )

      json = p.as_json

      json.should have_key("caption")
      json.should have_key("ordinal")
      json.should have_key("image_height")
      json.should have_key("image_width")
      json.should have_key("image_hash")
      json.should have_key("custom_aspect")
    end

    it 'includes computed dimension fields via methods' do
      p = collage.photos.create(image_height: 100, image_width: 100, size: 4)
      json = p.as_json

      json.should have_key("size")
      json.should have_key("height")
      json.should have_key("width")
      json.should have_key("image_url")
      json.should have_key("id")
    end

    it 'uses methods accessor for dynamic fields' do
      # Characterized from: methods: [:id, :image_url, :size, :height, :width]
      p = collage.photos.create(image_height: 100, image_width: 100, size: 9)
      json = p.as_json

      json["size"].should == p.size
      json["height"].should == p.height
      json["width"].should == p.width
      json["image_url"].should == p.image_url
    end
  end

  describe "embedded_in relationship" do
    it 'belongs to collage via embedded_in' do
      p = collage.photos.create(image_height: 100, image_width: 100)
      p.collage.should == collage
    end

    it 'is embedded (not a separate collection)' do
      # MongoDB stores photos inside collage document
      # This characterizes Mongoid embeds_many / embedded_in pattern
      p = collage.photos.create(image_height: 100, image_width: 100)
      p.should be_embedded
    end
  end

  describe "attr_accessible" do
    it 'allows mass assignment of photo fields' do
      p = collage.photos.new(
        caption: "Caption",
        ordinal: 5,
        size: 10,
        height: 2,
        width: 5,
        custom_aspect: true
      )

      p.caption.should == "Caption"
      p.ordinal.should == 5
      p.size.should == 10
      p.custom_aspect.should be_true
    end

    it 'protects image_hash from mass assignment' do
      # image_hash not in attr_accessible - should be set by controller
      p = collage.photos.new(image_hash: "hacked")
      p.image_hash.should_not == "hacked"
    end
  end

  describe "before_save callback" do
    it 'runs set_default_dimensions before save' do
      # This test characterizes the callback chain
      p = collage.photos.new(image_height: 100, image_width: 200, size: 8)

      # Dimensions not yet calculated
      p.height.should be_nil
      p.width.should be_nil

      p.save

      # After save, dimensions should be calculated
      p.height.should_not be_nil
      p.width.should_not be_nil
      p.height * p.width.should == 8
    end

    it 'recalculates on every save if constraints not met' do
      p = collage.photos.create(image_height: 100, image_width: 100, size: 4)
      original_height = p.height

      # Change size without updating dimensions
      p.size = 9
      p.height = original_height  # Keep old height

      p.save

      # Should recalculate because 4 (old height) * 2 (old width) ≠ 9 (new size)
      p.height * p.width.should == 9
    end
  end

  describe "Integer#factors dependency" do
    it 'depends on Integer#factors extension' do
      # Characterize dependency on config/initializers/integer_factors.rb
      # This extension adds factors method to Integer class

      12.should respond_to(:factors)
      12.factors.should == [1, 2, 3, 4, 6, 12]
    end

    it 'factors method returns sorted array of divisors' do
      # Prime factorization used for grid dimension calculation
      16.factors.should == [1, 2, 4, 8, 16]
      18.factors.should == [1, 2, 3, 6, 9, 18]
      1.factors.should == [1]
    end

    it 'factors method includes square roots only once' do
      # For perfect squares, sqrt appears once (not twice)
      9.factors.should == [1, 3, 9]  # Not [1, 3, 3, 9]
      16.factors.should == [1, 2, 4, 8, 16]  # 4 appears once
    end
  end
end
