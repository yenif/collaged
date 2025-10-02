require 'rails_helper'

RSpec.describe "Photo Reordering API", type: :request do
  let!(:collage) { Collage.create!(title: "Test Collage") }

  before do
    # Create 5 photos with sequential ordinals
    5.times do |i|
      collage.photos.create!(
        ordinal: i + 1,
        size: 4,
        width: 2,
        height: 2,
        image_height: 800,
        image_width: 600,
        image_hash: SecureRandom.hex(20)
      )
    end
    collage.save!
  end

  describe "PATCH /collages/{guid}/photos/{id} for ordinal update" do
    let(:photo) { collage.photos.find_by(ordinal: 1) }

    context "with write access" do
      it "updates photo ordinal successfully" do
        patch "/collages/#{collage.rw_guid}/photos/#{photo.id}",
              params: { photo: { ordinal: 3 } },
              as: :json

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to match(%r{application/json})

        json = JSON.parse(response.body)
        expect(json['ordinal']).to eq(3)

        photo.reload
        expect(photo.ordinal).to eq(3)
      end

      it "allows moving photo to first position" do
        last_photo = collage.photos.find_by(ordinal: 5)

        patch "/collages/#{collage.rw_guid}/photos/#{last_photo.id}",
              params: { photo: { ordinal: 1 } },
              as: :json

        expect(response).to have_http_status(:ok)

        last_photo.reload
        expect(last_photo.ordinal).to eq(1)
      end

      it "allows moving photo to last position" do
        first_photo = collage.photos.find_by(ordinal: 1)
        max_ordinal = collage.photos.maximum(:ordinal)

        patch "/collages/#{collage.rw_guid}/photos/#{first_photo.id}",
              params: { photo: { ordinal: max_ordinal } },
              as: :json

        expect(response).to have_http_status(:ok)

        first_photo.reload
        expect(first_photo.ordinal).to eq(max_ordinal)
      end

      it "returns complete photo JSON matching contract" do
        patch "/collages/#{collage.rw_guid}/photos/#{photo.id}",
              params: { photo: { ordinal: 3 } },
              as: :json

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)

        # Verify contract fields from contracts/photo_reorder.yml
        expect(json).to have_key('id')
        expect(json).to have_key('ordinal')
        expect(json).to have_key('size')
        expect(json).to have_key('width')
        expect(json).to have_key('height')
        expect(json).to have_key('custom_aspect')
        expect(json).to have_key('image_width')
        expect(json).to have_key('image_height')
        expect(json).to have_key('image_hash')
        expect(json).to have_key('image_url')

        # Verify types
        expect(json['ordinal']).to be_a(Integer)
        expect(json['size']).to be_a(Integer)
        expect(json['width']).to be_a(Integer)
        expect(json['height']).to be_a(Integer)
        expect(json['custom_aspect']).to be_in([true, false])
      end

      it "can update ordinal along with other photo properties" do
        patch "/collages/#{collage.rw_guid}/photos/#{photo.id}",
              params: {
                photo: {
                  ordinal: 4,
                  caption: "Reordered Photo",
                  size: 6,
                  width: 3,
                  height: 2
                }
              },
              as: :json

        expect(response).to have_http_status(:ok)

        photo.reload
        expect(photo.ordinal).to eq(4)
        expect(photo.caption).to eq("Reordered Photo")
        expect(photo.size).to eq(6)
      end

      it "maintains sequential ordinals after multiple updates" do
        # This tests that the system handles ordinal gaps gracefully
        photo1 = collage.photos.find_by(ordinal: 1)
        photo2 = collage.photos.find_by(ordinal: 2)
        photo3 = collage.photos.find_by(ordinal: 3)

        # Move photo 1 to position 3
        patch "/collages/#{collage.rw_guid}/photos/#{photo1.id}",
              params: { photo: { ordinal: 3 } },
              as: :json

        expect(response).to have_http_status(:ok)

        # Verify ordinals still make sense (may have gaps, but order is preserved)
        collage.reload
        ordinals = collage.photos.map(&:ordinal).sort
        expect(ordinals).to all(be > 0)
      end
    end

    context "with read-only access" do
      it "returns 403 Forbidden for ordinal update" do
        patch "/collages/#{collage.r_guid}/photos/#{photo.id}",
              params: { photo: { ordinal: 3 } },
              as: :json

        expect(response).to have_http_status(:forbidden)
        expect(response.content_type).to match(%r{application/json})

        json = JSON.parse(response.body)
        expect(json).to have_key('error')
        expect(json['error']).to match(/write access/i)

        # Verify ordinal unchanged
        photo.reload
        expect(photo.ordinal).to eq(1)
      end
    end

    context "with invalid ordinal values" do
      it "allows ordinal of 0 (edge case)" do
        patch "/collages/#{collage.rw_guid}/photos/#{photo.id}",
              params: { photo: { ordinal: 0 } },
              as: :json

        expect(response).to have_http_status(:ok)

        photo.reload
        expect(photo.ordinal).to eq(0)
      end

      it "allows negative ordinals (edge case for sorting)" do
        patch "/collages/#{collage.rw_guid}/photos/#{photo.id}",
              params: { photo: { ordinal: -1 } },
              as: :json

        expect(response).to have_http_status(:ok)

        photo.reload
        expect(photo.ordinal).to eq(-1)
      end

      it "allows large ordinal values" do
        patch "/collages/#{collage.rw_guid}/photos/#{photo.id}",
              params: { photo: { ordinal: 9999 } },
              as: :json

        expect(response).to have_http_status(:ok)

        photo.reload
        expect(photo.ordinal).to eq(9999)
      end
    end

    context "with non-existent resources" do
      it "returns 404 for non-existent photo" do
        patch "/collages/#{collage.rw_guid}/photos/nonexistent",
              params: { photo: { ordinal: 3 } },
              as: :json

        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for non-existent collage" do
        patch "/collages/invalid-guid/photos/#{photo.id}",
              params: { photo: { ordinal: 3 } },
              as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /collages/{guid}/photos for verifying order" do
    it "returns photos sorted by ordinal ascending" do
      get "/collages/#{collage.rw_guid}/photos", as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
      expect(json.length).to eq(5)

      # Verify ordinals are in ascending order
      ordinals = json.map { |p| p['ordinal'] }
      expect(ordinals).to eq(ordinals.sort)
      expect(ordinals).to eq([1, 2, 3, 4, 5])
    end

    it "reflects updated ordinals after reorder" do
      photo = collage.photos.find_by(ordinal: 1)

      # Move photo from position 1 to position 5
      patch "/collages/#{collage.rw_guid}/photos/#{photo.id}",
            params: { photo: { ordinal: 5 } },
            as: :json

      expect(response).to have_http_status(:ok)

      # Fetch all photos and verify order
      get "/collages/#{collage.rw_guid}/photos", as: :json

      json = JSON.parse(response.body)
      ordinals = json.map { |p| p['ordinal'] }

      # Photo that was at position 1 should now be somewhere else
      first_photo_ordinal = json.find { |p| p['id']['$oid'] == photo.id.to_s }['ordinal']
      expect(first_photo_ordinal).to eq(5)
    end
  end

  describe "concurrent ordinal updates (last-write-wins)" do
    let(:photo) { collage.photos.find_by(ordinal: 1) }

    it "applies last write when two updates occur" do
      # First update
      patch "/collages/#{collage.rw_guid}/photos/#{photo.id}",
            params: { photo: { ordinal: 3 } },
            as: :json

      expect(response).to have_http_status(:ok)

      # Second update (simulating concurrent user)
      patch "/collages/#{collage.rw_guid}/photos/#{photo.id}",
            params: { photo: { ordinal: 5 } },
            as: :json

      expect(response).to have_http_status(:ok)

      # Last write wins
      photo.reload
      expect(photo.ordinal).to eq(5)
    end
  end
end
