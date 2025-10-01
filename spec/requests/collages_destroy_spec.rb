require 'rails_helper'

RSpec.describe "DELETE /collages/{guid}", type: :request do
  let!(:collage) { Collage.create!(title: "Test Collage") }

  describe "deleting a collage" do
    context "with read-write GUID" do
      it "returns HTTP 204 and deletes the collage" do
        expect {
          delete "/collages/#{collage.rw_guid}", as: :json
        }.to change { Collage.count }.by(-1)

        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end

      it "deletes associated photos" do
        collage.photos.create!(ordinal: 0, image_height: 100, image_width: 100)
        collage.photos.create!(ordinal: 1, image_height: 200, image_width: 150)

        expect(collage.photos.count).to eq(2)

        delete "/collages/#{collage.rw_guid}", as: :json

        expect(response).to have_http_status(:no_content)
        expect(Collage.where(rw_guid: collage.rw_guid).first).to be_nil
      end
    end

    context "with read-only GUID" do
      it "returns HTTP 403 Forbidden" do
        expect {
          delete "/collages/#{collage.r_guid}", as: :json
        }.not_to change { Collage.count }

        expect(response).to have_http_status(:forbidden)
        expect(response.content_type).to match(%r{application/json})

        json = JSON.parse(response.body)
        expect(json).to have_key('error')
        expect(json['error']).to match(/write access/i)
      end
    end

    context "with invalid GUID" do
      it "returns HTTP 404" do
        delete "/collages/nonexistent-guid", as: :json

        expect(response).to have_http_status(:not_found)
        expect(response.content_type).to match(%r{application/json})
      end
    end
  end
end
