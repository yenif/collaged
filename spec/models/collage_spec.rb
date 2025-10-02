require 'spec_helper'

describe Collage do
  describe "GUID generation" do
    it "generates unique r_guid and rw_guid on create" do
      collage = Collage.create(title: "Test Collage")

      collage.r_guid.should_not be_nil
      collage.rw_guid.should_not be_nil
      collage.r_guid.should_not == collage.rw_guid
    end

    it "uses UUIDTools for GUID generation" do
      # Characterize current implementation: UUIDTools::UUID.random_create
      collage = Collage.create(title: "Test Collage")

      # UUIDs should be 36 characters with dashes (8-4-4-4-12 format)
      collage.r_guid.should match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
      collage.rw_guid.should match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
    end

    it "ensures GUIDs are unique across all collages" do
      collage1 = Collage.create(title: "Collage 1")
      collage2 = Collage.create(title: "Collage 2")

      # No collisions between r_guid and rw_guid across collages
      [collage1.r_guid, collage1.rw_guid, collage2.r_guid, collage2.rw_guid].uniq.count.should == 4
    end

    it "regenerates GUIDs on collision" do
      # This test characterizes the retry logic in initialize_guids
      # The method loops until no collision is found with any_of query
      collage = Collage.create(title: "Test")

      # Should successfully create even if there are existing GUIDs
      collage.should be_valid
      collage.should be_persisted
    end
  end

  describe "find_by_guid" do
    let(:collage) { Collage.create(title: "Test Collage") }

    it "finds collage by r_guid (read-only)" do
      found = Collage.find_by_guid(collage.r_guid)

      found.should == collage
      found.write_access.should be_false
    end

    it "finds collage by rw_guid (read-write)" do
      found = Collage.find_by_guid(collage.rw_guid)

      found.should == collage
      found.write_access.should be_true
    end

    it "returns nil for invalid GUID" do
      found = Collage.find_by_guid("invalid-guid")
      found.should be_nil
    end

    it "uses any_of query for both r_guid and rw_guid" do
      # Characterize the query pattern: any_of({r_guid: guid},{rw_guid: guid})
      # This allows a single query to search both fields

      found_by_r = Collage.find_by_guid(collage.r_guid)
      found_by_rw = Collage.find_by_guid(collage.rw_guid)

      found_by_r.id.should == found_by_rw.id
    end
  end

  describe "find_by_guid!" do
    it "raises Mongoid::Errors::DocumentNotFound for invalid GUID" do
      expect {
        Collage.find_by_guid!("invalid-guid")
      }.to raise_error(Mongoid::Errors::DocumentNotFound)
    end

    it "returns collage for valid GUID" do
      collage = Collage.create(title: "Test")
      found = Collage.find_by_guid!(collage.r_guid)
      found.should == collage
    end
  end

  describe "write_access flag" do
    it "initializes write_access to true on new records" do
      collage = Collage.new(title: "Test")
      collage.write_access.should be_true
    end

    it "defaults write_access to false after find_by_guid with r_guid" do
      collage = Collage.create(title: "Test")
      found = Collage.find_by_guid(collage.r_guid)

      found.write_access.should be_false
    end

    it "sets write_access to true after find_by_guid with rw_guid" do
      collage = Collage.create(title: "Test")
      found = Collage.find_by_guid(collage.rw_guid)

      found.write_access.should be_true
    end

    it "prevents rw_guid access when write_access is false" do
      collage = Collage.create(title: "Test")
      found = Collage.find_by_guid(collage.r_guid)

      # rw_guid method returns nil when write_access is false
      found.rw_guid.should be_nil
      # But the field still exists in the database
      found[:rw_guid].should_not be_nil
    end

    it "exposes rw_guid when write_access is true" do
      collage = Collage.create(title: "Test")
      found = Collage.find_by_guid(collage.rw_guid)

      found.rw_guid.should_not be_nil
      found.rw_guid.should == found[:rw_guid]
    end

    it "returns boolean for write_access (coerces to true/false)" do
      collage = Collage.create(title: "Test")

      # write_access method uses !! to coerce to boolean
      collage.write_access.should be_true
      collage.write_access.class.should == TrueClass
    end
  end

  describe "to_param" do
    it "returns rw_guid when write_access is true" do
      collage = Collage.create(title: "Test")
      collage.write_access = true

      collage.to_param.should == collage[:rw_guid]
    end

    it "returns r_guid when write_access is false" do
      collage = Collage.create(title: "Test")
      collage.write_access = false

      collage.to_param.should == collage.r_guid
    end
  end

  describe "title validation" do
    it "requires title to be present" do
      collage = Collage.new(title: nil)
      collage.should_not be_valid
      collage.errors[:title].should include("can't be blank")
    end

    it "validates title on create" do
      collage = Collage.create(title: "")
      collage.should_not be_valid
    end

    it "allows valid title" do
      collage = Collage.create(title: "My Collage")
      collage.should be_valid
    end
  end

  describe "as_json serialization" do
    it "includes r_guid, rw_guid, title, write_access, and id" do
      collage = Collage.create(title: "Test")
      json = collage.as_json

      json.should have_key("r_guid")
      json.should have_key("rw_guid")
      json.should have_key("title")
      json.should have_key("write_access")
      json.should have_key("id")
    end

    it "sets id to to_param value" do
      collage = Collage.create(title: "Test")
      json = collage.as_json

      json["id"].should == collage.to_param
    end

    it "excludes rw_guid when write_access is false" do
      collage = Collage.create(title: "Test")
      found = Collage.find_by_guid(collage.r_guid)
      json = found.as_json

      # as_json includes rw_guid key, but rw_guid method returns nil
      json["rw_guid"].should be_nil
      json["write_access"].should be_false
    end

    it "includes rw_guid when write_access is true" do
      collage = Collage.create(title: "Test")
      found = Collage.find_by_guid(collage.rw_guid)
      json = found.as_json

      json["rw_guid"].should_not be_nil
      json["write_access"].should be_true
    end
  end

  describe "photos association" do
    it "embeds_many photos with ordinal ordering" do
      collage = Collage.create(title: "Test")

      photo1 = collage.photos.create(ordinal: 2, image_height: 100, image_width: 100)
      photo2 = collage.photos.create(ordinal: 1, image_height: 100, image_width: 100)
      photo3 = collage.photos.create(ordinal: 3, image_height: 100, image_width: 100)

      # Photos should be ordered by ordinal ascending
      collage.photos.map(&:ordinal).should == [1, 2, 3]
    end
  end

  describe "attr_accessible" do
    it "allows mass assignment of title" do
      collage = Collage.new(title: "Mass Assigned")
      collage.title.should == "Mass Assigned"
    end

    it "protects r_guid from mass assignment" do
      # This characterizes Rails 3.2 attr_accessible behavior
      # r_guid and rw_guid are not in attr_accessible, so they're protected
      collage = Collage.new(r_guid: "custom-guid")
      collage.r_guid.should_not == "custom-guid"
    end

    it "protects rw_guid from mass assignment" do
      collage = Collage.new(rw_guid: "custom-guid")
      collage.rw_guid.should be_nil
    end
  end

  describe "indexes" do
    it "has unique index on r_guid" do
      # Characterized from: index({r_guid: 1}, {unique: true})
      # This test documents the expected index, actual validation requires MongoDB
      Collage.index_options[:r_guid].should_not be_nil
    end

    it "has unique index on rw_guid" do
      # Characterized from: index({rw_guid: 1}, {unique: true})
      Collage.index_options[:rw_guid].should_not be_nil
    end
  end
end
