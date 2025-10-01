require 'rails_helper'

RSpec.describe "POST /collages/{guid}/photos", type: :request do
  let!(:collage) { Collage.create!(title: "Test Collage") }
  let(:valid_image) do
    fixture_file_upload(Rails.root.join('spec', 'fixtures', 'test_image.jpg'), 'image/jpeg')
  end

  describe "uploading a photo" do
    context "with read-write GUID and valid image" do
      it "returns HTTP 201 with photo data" do
        post "/collages/#{collage.rw_guid}/photos",
             params: { photo: { image: valid_image, ordinal: 0 } }

        expect(response).to have_http_status(:created)
        expect(response.content_type).to match(%r{application/json})

        json = JSON.parse(response.body)
        expect(json['ordinal']).to eq(0)
        expect(json['image_url']).to be_present
        expect(json['image_height']).to be_a(Integer)
        expect(json['image_width']).to be_a(Integer)
        expect(json['image_hash']).to be_present

        # Check Location header
        expect(response.headers['Location']).to match(%r{/collages/#{collage.rw_guid}/photos/\w+})
      end

      it "increments photo count" do
        expect {
          post "/collages/#{collage.rw_guid}/photos",
               params: { photo: { image: valid_image, ordinal: 0 } }
        }.to change { collage.reload.photos.count }.by(1)
      end
    end

    context "with read-only GUID" do
      it "returns HTTP 403 Forbidden" do
        post "/collages/#{collage.r_guid}/photos",
             params: { photo: { image: valid_image, ordinal: 0 } }

        expect(response).to have_http_status(:forbidden)
        expect(response.content_type).to match(%r{application/json})

        json = JSON.parse(response.body)
        expect(json).to have_key('error')
        expect(json['error']).to match(/write access/i)
      end
    end

    context "with file larger than 10MB" do
      it "returns HTTP 413 Payload Too Large" do
        # Create a mock file that reports as >10MB
        large_file = double('large_file',
                           original_filename: 'large.jpg',
                           content_type: 'image/jpeg',
                           size: 11.megabytes,
                           read: 'fake data')

        post "/collages/#{collage.rw_guid}/photos",
             params: { photo: { image: large_file, ordinal: 0 } }

        expect(response).to have_http_status(:payload_too_large)
      end
    end

    context "with invalid image format" do
      let(:invalid_file) do
        fixture_file_upload(Rails.root.join('spec', 'fixtures', 'test.txt'), 'text/plain')
      end

      it "returns HTTP 422 Unprocessable Entity" do
        post "/collages/#{collage.rw_guid}/photos",
             params: { photo: { image: invalid_file, ordinal: 0 } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to match(%r{application/json})

        json = JSON.parse(response.body)
        expect(json).to have_key('image')
      end
    end

    context "with duplicate image (same hash)" do
      before do
        # Create first photo with the image
        post "/collages/#{collage.rw_guid}/photos",
             params: { photo: { image: valid_image, ordinal: 0 } }
      end

      it "returns HTTP 409 Conflict for duplicate" do
        post "/collages/#{collage.rw_guid}/photos",
             params: { photo: { image: valid_image, ordinal: 1 } }

        expect(response).to have_http_status(:conflict)
        expect(response.content_type).to match(%r{application/json})

        json = JSON.parse(response.body)
        expect(json).to have_key('error')
        expect(json['error']).to match(/duplicate/i)
      end
    end
  end
end
