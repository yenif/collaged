require 'rails_helper'

RSpec.describe "GET /collages/{guid}", type: :request do
  let!(:collage) { Collage.create!(title: "Test Collage") }

  describe "retrieving a collage" do
    context "with read-only GUID" do
      it "returns HTTP 200 with read-only data" do
        get "/collages/#{collage.r_guid}", as: :json

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to match(%r{application/json})

        json = JSON.parse(response.body)
        expect(json['title']).to eq('Test Collage')
        expect(json['r_guid']).to eq(collage.r_guid)
        expect(json['rw_guid']).to be_nil  # Should not expose write GUID
        expect(json['write_access']).to be false
        expect(json['id']).to eq(collage.r_guid)
      end
    end

    context "with read-write GUID" do
      it "returns HTTP 200 with read-write data" do
        get "/collages/#{collage.rw_guid}", as: :json

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to match(%r{application/json})

        json = JSON.parse(response.body)
        expect(json['title']).to eq('Test Collage')
        expect(json['r_guid']).to eq(collage.r_guid)
        expect(json['rw_guid']).to eq(collage.rw_guid)  # Should expose write GUID
        expect(json['write_access']).to be true
        expect(json['id']).to eq(collage.rw_guid)
      end
    end

    context "with invalid GUID" do
      it "returns HTTP 404" do
        get "/collages/nonexistent-guid", as: :json

        expect(response).to have_http_status(:not_found)
        expect(response.content_type).to match(%r{application/json})
      end
    end

    context "with photos" do
      before do
        collage.photos.create!(ordinal: 0, image_height: 100, image_width: 100)
        collage.photos.create!(ordinal: 1, image_height: 200, image_width: 150)
      end

      it "includes photo data in response" do
        get "/collages/#{collage.r_guid}", as: :json

        json = JSON.parse(response.body)
        expect(json['photos']).to be_an(Array)
        expect(json['photos'].length).to eq(2)
        expect(json['photos'][0]['ordinal']).to eq(0)
        expect(json['photos'][1]['ordinal']).to eq(1)
      end
    end
  end
end
