require 'rails_helper'

RSpec.describe "POST /collages", type: :request do
  describe "creating a new collage" do
    context "with valid title" do
      it "returns HTTP 201 with collage data" do
        post '/collages', params: { collage: { title: "My Test Collage" } }, as: :json

        expect(response).to have_http_status(:created)
        expect(response.content_type).to match(%r{application/json})

        json = JSON.parse(response.body)
        expect(json['title']).to eq('My Test Collage')
        expect(json['r_guid']).to be_present
        expect(json['r_guid']).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
        expect(json['rw_guid']).to be_present
        expect(json['rw_guid']).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
        expect(json['r_guid']).not_to eq(json['rw_guid'])
        expect(json['write_access']).to be true
        expect(json['id']).to eq(json['rw_guid'])

        # Check Location header
        expect(response.headers['Location']).to eq("/collages/#{json['rw_guid']}")
      end

      it "generates unique GUIDs" do
        post '/collages', params: { collage: { title: "First" } }, as: :json
        first_guid = JSON.parse(response.body)['r_guid']

        post '/collages', params: { collage: { title: "Second" } }, as: :json
        second_guid = JSON.parse(response.body)['r_guid']

        expect(first_guid).not_to eq(second_guid)
      end
    end

    context "with blank title" do
      it "returns HTTP 422 with validation errors" do
        post '/collages', params: { collage: { title: "" } }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to match(%r{application/json})

        json = JSON.parse(response.body)
        expect(json).to have_key('title')
      end
    end

    context "without title parameter" do
      it "returns HTTP 422" do
        post '/collages', params: { collage: {} }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
