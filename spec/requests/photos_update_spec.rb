require 'rails_helper'

RSpec.describe "PATCH /collages/{guid}/photos/{id}", type: :request do
  let!(:collage) { Collage.create!(title: "Test Collage") }
  let!(:photo) { collage.photos.create!(ordinal: 0, image_height: 100, image_width: 100, size: 1) }

  describe "updating a photo" do
    context "with read-write GUID and valid dimensions" do
      it "returns HTTP 200 with updated photo data" do
        patch "/collages/#{collage.rw_guid}/photos/#{photo.id}",
              params: { photo: { size: 4, width: 2, height: 2 } },
              as: :json

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to match(%r{application/json})

        json = JSON.parse(response.body)
        expect(json['size']).to eq(4)
        expect(json['width']).to eq(2)
        expect(json['height']).to eq(2)

        # Verify database update
        photo.reload
        expect(photo.size).to eq(4)
        expect(photo.width).to eq(2)
        expect(photo.height).to eq(2)
      end

      it "allows updating ordinal" do
        patch "/collages/#{collage.rw_guid}/photos/#{photo.id}",
              params: { photo: { ordinal: 5 } },
              as: :json

        expect(response).to have_http_status(:ok)
        photo.reload
        expect(photo.ordinal).to eq(5)
      end

      it "allows updating caption" do
        patch "/collages/#{collage.rw_guid}/photos/#{photo.id}",
              params: { photo: { caption: "My Photo" } },
              as: :json

        expect(response).to have_http_status(:ok)
        photo.reload
        expect(photo.caption).to eq("My Photo")
      end
    end

    context "with read-only GUID" do
      it "returns HTTP 403 Forbidden" do
        patch "/collages/#{collage.r_guid}/photos/#{photo.id}",
              params: { photo: { size: 4 } },
              as: :json

        expect(response).to have_http_status(:forbidden)
        expect(response.content_type).to match(%r{application/json})

        json = JSON.parse(response.body)
        expect(json).to have_key('error')
        expect(json['error']).to match(/write access/i)
      end
    end

    context "with invalid dimensions (size != width × height)" do
      it "returns HTTP 422 Unprocessable Entity" do
        patch "/collages/#{collage.rw_guid}/photos/#{photo.id}",
              params: { photo: { size: 4, width: 3, height: 2 } },
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to match(%r{application/json})

        json = JSON.parse(response.body)
        expect(json).to have_key('size')
        expect(json['size']).to match(/must equal width.*height/i)
      end
    end

    context "with non-existent photo" do
      it "returns HTTP 404" do
        patch "/collages/#{collage.rw_guid}/photos/nonexistent",
              params: { photo: { size: 4 } },
              as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with custom_aspect flag" do
      it "allows setting custom aspect ratio" do
        patch "/collages/#{collage.rw_guid}/photos/#{photo.id}",
              params: { photo: { custom_aspect: true, size: 4, width: 1, height: 4 } },
              as: :json

        expect(response).to have_http_status(:ok)
        photo.reload
        expect(photo.custom_aspect).to be true
        expect(photo.height).to eq(4)
        expect(photo.width).to eq(1)
      end
    end
  end
end
